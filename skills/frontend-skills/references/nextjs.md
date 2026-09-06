# Next.js App Router Reference (14, 15, 16)

Dense reference for App Router patterns. Read the section you need; don't read end-to-end.

## File Conventions

```
app/
├── layout.tsx          # Required root layout
├── page.tsx            # /
├── loading.tsx         # Suspense fallback for the segment
├── error.tsx           # Error boundary (must be Client)
├── not-found.tsx       # 404 UI
├── global-error.tsx    # Catches errors in root layout (needs <html>+<body>)
├── route.ts            # API endpoint (cannot coexist with page.tsx for GET)
├── template.tsx        # Like layout but remounts on navigation
├── default.tsx         # Parallel-route fallback
├── forbidden.tsx       # 403 (rendered by forbidden())
├── unauthorized.tsx    # 401 (rendered by unauthorized())
├── blog/[slug]/page.tsx       # Dynamic segment
├── shop/[...path]/page.tsx    # Catch-all
├── docs/[[...path]]/page.tsx  # Optional catch-all
├── (marketing)/page.tsx       # Route group (no URL impact)
└── _components/Button.tsx     # Private folder (excluded from routing)
```

**Parallel routes:**
```
app/
├── @analytics/page.tsx
├── @sidebar/page.tsx
└── layout.tsx          # Receives { analytics, sidebar } as props
```

**Intercepting routes** (modals on top of an existing route):
```
app/feed/page.tsx
app/@modal/(.)photo/[id]/page.tsx    # (.) same level, (..) up one, (...) from root
app/photo/[id]/page.tsx
```

**Middleware rename (v16+):** `middleware.ts` → `proxy.ts`, `middleware()` → `proxy()`. Same matchers. `npx @next/codemod@latest upgrade` migrates.

## Server vs Client Components

### Defaults

- **Every component is a Server Component** unless its file (or a file it's imported into) has `'use client'` at the top.
- Server components can be `async`, can `await`, can `import` server-only modules, can read databases/env directly.
- Client components run in the browser + during hydration. They cannot be `async`, cannot use server-only modules, must receive serializable props.

### What CANNOT cross the Server → Client boundary

| Disallowed | Why | Workaround |
|---|---|---|
| Functions | Not serializable | Define inside client OR mark as Server Action with `'use server'` |
| `Date` objects | Silently coerced to string, then crash on `.getFullYear()` | `.toISOString()` server-side, re-parse on client |
| `Map`, `Set`, `WeakMap`, `WeakSet` | Not serializable | Convert to object / array |
| Class instances | Methods stripped | Pass plain objects |
| `Symbol` (non-global) | Not serializable | Use string keys |
| Circular references | Crashes | Restructure |

### The "async client component" trap

```tsx
// WRONG — runtime error
'use client'
export default async function Profile() {
  const user = await getUser()
  return <div>{user.name}</div>
}

// RIGHT — fetch in server parent
// page.tsx
export default async function Page() {
  const user = await getUser()
  return <Profile user={user} />
}
// Profile.tsx
'use client'
export function Profile({ user }: { user: User }) { return <div>{user.name}</div> }
```

### Where to put `'use client'`

Push it to the **smallest leaf that needs interactivity**. Server parents stay async. Never put `'use client'` at the top of `page.tsx` "just because it has a button" — extract the button.

### Server Actions can cross the boundary

A function marked `'use server'` is special: it can be passed as a prop to a Client Component or used as a `<form action={…}>`.

```tsx
// actions.ts
'use server'
export async function submit(formData: FormData) { /* … */ }

// page.tsx (server)
import { submit } from './actions'
export default function Page() { return <ClientForm onSubmit={submit} /> }
```

## Next.js 16 Cache Components

Enable in `next.config.ts`:

```ts
const nextConfig: NextConfig = { cacheComponents: true }
```

This replaces `experimental.ppr`. With it on, content falls into three buckets:

| Bucket | How | Behavior |
|---|---|---|
| **Static** | Sync code, no `await` on dynamic | Prerendered at build |
| **Cached** | `'use cache'` directive on file/component/function | Served from cache, revalidates per `cacheLife` |
| **Dynamic** | Async code accessing `cookies()`/`headers()`/`searchParams`/uncached `fetch` | Must be inside `<Suspense>`; streams in |

### `'use cache'`

```tsx
// File-level
'use cache'
export default async function Page() { return <div>{await getData()}</div> }

// Component-level
async function Stats() {
  'use cache'
  cacheLife('hours')
  cacheTag('stats')
  return <StatsDisplay stats={await db.stats.aggregate()} />
}

// Function-level
export async function getProduct(id: string) {
  'use cache'
  cacheTag('products', `product-${id}`)
  return db.products.findUnique({ where: { id } })
}
```

**Import path — verify your Next.js version:**

```tsx
// Stabilized exports (Next.js docs use these names)
import { cacheLife, cacheTag } from 'next/cache'

// Some Next.js 16 builds still ship them under `unstable_` — alias if so:
import {
  unstable_cacheLife as cacheLife,
  unstable_cacheTag as cacheTag,
} from 'next/cache'
```

Check what your installed version exports. If `cacheLife` is undefined at runtime, switch to the `unstable_*` aliased import. `revalidateTag`, `revalidatePath`, and `updateTag` are stable under their bare names.

**Cache profiles:**
```tsx
'use cache'              // default: 5m stale / 15m revalidate
'use cache: remote'      // platform-provided (Redis, KV)
'use cache: private'     // allows cookies()/headers() inside (compliance escape hatch)
```

**`cacheLife()`:**
```tsx
cacheLife('hours')                                // built-in: minutes/hours/days/weeks/max
cacheLife({ stale: 3600, revalidate: 7200, expire: 86400 })   // explicit seconds
```

**Cache keys are automatic:** built from build ID + function ID hash + serializable args + closure values. No manual `keyParts` needed.

**Runtime data constraint:** Cannot call `cookies()`, `headers()`, or read `searchParams` *inside* a `'use cache'` function. Extract outside and pass as args (which become part of the key), or use `'use cache: private'`.

```tsx
// WRONG
async function Cached() { 'use cache'; const s = (await cookies()).get('s')?.value; … }

// RIGHT
async function Page() {
  const s = (await cookies()).get('s')?.value
  return <Cached sessionId={s} />
}
async function Cached({ sessionId }: { sessionId: string }) {
  'use cache'
  return <div>{await fetchUserData(sessionId)}</div>
}
```

### Invalidation

```tsx
// Same-request immediate refresh
import { updateTag } from 'next/cache'
'use server'
export async function updateProduct(id: string) {
  await db.products.update(...)
  updateTag(`product-${id}`)
}

// Background revalidation
import { revalidateTag, revalidatePath } from 'next/cache'
revalidateTag('posts')
revalidatePath('/posts')
```

### Migration table

| Old | New |
|---|---|
| `experimental.ppr` | `cacheComponents: true` |
| `export const dynamic = 'force-dynamic'` | Remove (default) |
| `export const dynamic = 'force-static'` | `'use cache'` + `cacheLife('max')` |
| `export const revalidate = N` | `cacheLife({ revalidate: N })` |
| `unstable_cache(fn, keyParts, opts)` | `'use cache'` directive on `fn` |

## Async APIs (Next.js 15+)

`params`, `searchParams`, `cookies()`, `headers()`, `draftMode()` are all **async**:

```tsx
// page.tsx
export default async function Page({
  params,
  searchParams,
}: {
  params: Promise<{ slug: string }>
  searchParams: Promise<{ q?: string }>
}) {
  const { slug } = await params
  const { q } = await searchParams
  const cookieStore = await cookies()
  const session = cookieStore.get('session')?.value
  return <div>{slug} / {q} / {session}</div>
}
```

Codemod: `npx @next/codemod@latest next-async-request-api .`

## Data Patterns

### Decision

```
Fetch from a Server Component?  → Just `await` it. No API.
Mutation from a UI form?         → Server Action.
External clients consume it?     → Route Handler.
Cacheable GET API for clients?   → Route Handler (HTTP cacheable).
```

### Server Component (preferred for reads)

```tsx
async function UsersPage() {
  const users = await db.user.findMany()
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>
}
```

### Server Action (preferred for mutations)

```tsx
// actions.ts
'use server'
import { revalidatePath } from 'next/cache'
export async function createPost(formData: FormData) {
  await db.post.create({ data: { title: formData.get('title') as string } })
  revalidatePath('/posts')
}

// new/page.tsx
export default function NewPost() {
  return (
    <form action={createPost}>
      <input name="title" required />
      <button type="submit">Create</button>
    </form>
  )
}
```

Benefits: end-to-end types, progressive enhancement, integrated with React transitions. Always POST, no GET cache.

### Route Handler

```tsx
// app/api/posts/route.ts
import { NextRequest, NextResponse } from 'next/server'
export async function GET(req: NextRequest) {
  const posts = await db.post.findMany()
  return NextResponse.json(posts)
}
export async function POST(req: NextRequest) {
  const body = await req.json()
  const post = await db.post.create({ data: body })
  return NextResponse.json(post, { status: 201 })
}
```

Use when: external API access, webhooks, REST for non-React clients, cacheable GETs.
Don't use when: internal reads (Server Components are better) or UI mutations (Server Actions are better).

### Avoiding waterfalls

**Sequential (bad):**
```tsx
const user = await getUser()       // wait
const posts = await getPosts()     // then wait
const comments = await getComments()  // then wait
```

**Parallel:**
```tsx
const [user, posts, comments] = await Promise.all([getUser(), getPosts(), getComments()])
```

**Streaming with Suspense (best for slow + slower):**
```tsx
async function Page() {
  return (
    <>
      <Suspense fallback={<UserSkeleton />}><UserSection /></Suspense>
      <Suspense fallback={<PostsSkeleton />}><PostsSection /></Suspense>
    </>
  )
}
async function UserSection() { return <div>{(await getUser()).name}</div> }
async function PostsSection() { return <PostList posts={await getPosts()} /> }
```

**Preload pattern (data starts loading before component renders):**
```tsx
// lib/data.ts
import { cache } from 'react'
export const getUser = cache(async (id: string) => db.user.findUnique({ where: { id } }))
export const preloadUser = (id: string) => { void getUser(id) }

// page.tsx
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  preloadUser(id)         // fire-and-forget; React.cache dedupes
  const profile = await getProfile(id)
  const user = await getUser(id)   // likely already resolved
  return <UserCard user={user} profile={profile} />
}
```

### Client-side data fetching (when you must)

Prefer passing initial data from a Server Component:
```tsx
async function Page() { const data = await fetchData(); return <Client initial={data} /> }
'use client'
function Client({ initial }) { const [data, setData] = useState(initial); … }
```

If fetching on mount: use SWR or TanStack Query for dedup and stale-while-revalidate, not raw `fetch` in `useEffect`.

## Error Handling

### `error.tsx` (segment-level boundary, must be Client)

```tsx
'use client'
export default function Error({
  error, reset,
}: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <button onClick={reset}>Try again</button>
    </div>
  )
}
```

### `global-error.tsx`

Must include `<html>` and `<body>` since it replaces the root layout.

### Don't `try/catch` navigation throws

`redirect()`, `permanentRedirect()`, `notFound()`, `forbidden()`, `unauthorized()` work by throwing a special error Next.js handles internally. Catching them breaks navigation.

```tsx
// WRONG — redirect throws, lands in catch, you return failure
try {
  const post = await db.post.create({ … })
  redirect(`/posts/${post.id}`)
} catch (e) {
  return { error: 'Failed' }
}

// RIGHT — redirect outside try/catch
let post
try {
  post = await db.post.create({ … })
} catch {
  return { error: 'Failed' }
}
redirect(`/posts/${post.id}`)

// RIGHT — re-throw navigation errors
import { unstable_rethrow } from 'next/navigation'
try {
  redirect('/x')
} catch (e) {
  unstable_rethrow(e)
  return { error: 'Other failure' }
}
```

### Triggering errors

```tsx
import { notFound, forbidden, unauthorized, redirect, permanentRedirect } from 'next/navigation'

if (!session) unauthorized()         // 401 → unauthorized.tsx
if (!session.canAccess) forbidden()  // 403 → forbidden.tsx
if (!post) notFound()                // 404 → closest not-found.tsx
redirect('/new')                     // 307
permanentRedirect('/v2')             // 308 (cached by browsers)
```

## Images

```tsx
import Image from 'next/image'

// Local — dimensions inferred
import hero from './hero.png'
<Image src={hero} alt="Hero" placeholder="blur" priority />

// Remote — width/height OR fill+sizes
<Image src="https://cdn.example.com/x.jpg" alt="X" width={800} height={400} />
<div className="relative h-64 w-full">
  <Image src="/hero.png" alt="Hero" fill sizes="100vw" className="object-cover" priority />
</div>
```

Remote hosts must be allowlisted in `next.config.ts`:
```ts
images: { remotePatterns: [{ protocol: 'https', hostname: 'cdn.example.com' }] }
```

`sizes` is **required when using `fill`** — without it, the browser downloads the largest version. Example: `sizes="(max-width: 768px) 100vw, 33vw"`.

`priority` only on the LCP image (the largest above-the-fold one). Don't put it on lazy/below-fold images.

`placeholder="blur"` requires `blurDataURL` for remote images.

## Fonts

```tsx
// app/layout.tsx
import { Inter } from 'next/font/google'
const inter = Inter({ subsets: ['latin'], display: 'swap' })
export default function Layout({ children }) {
  return <html lang="en" className={inter.className}><body>{children}</body></html>
}
```

For Tailwind: expose as CSS variable, then use in `tailwind.config.ts`:
```ts
const inter = Inter({ subsets: ['latin'], variable: '--font-inter' })
// <html className={inter.variable}>

// tailwind.config.ts
theme: { fontFamily: { sans: ['var(--font-inter)', 'sans-serif'] } }
```

Local fonts via `next/font/local` with `src` array.

## Bundling

`optimizePackageImports` in `next.config.ts` is mandatory for icon and component libraries:

```ts
const nextConfig: NextConfig = {
  experimental: {
    optimizePackageImports: [
      'lucide-react', '@radix-ui/react-icons', '@tabler/icons-react',
      'react-icons', '@mui/material', '@mui/icons-material',
      '@headlessui/react', 'lodash', 'date-fns', 'ramda',
    ],
  },
}
```

Without it, `import { Bell } from 'lucide-react'` loads ~1,500 modules and adds 200–800 ms of cold-start time.

CSS: import in components, not via `<link rel="stylesheet">`. Polyfills: already included; don't manually add `core-js`.

## Scripts

`next/script` for third-party scripts:
```tsx
import Script from 'next/script'
<Script src="https://example.com/analytics.js" strategy="afterInteractive" />
```

Strategies: `beforeInteractive`, `afterInteractive` (default), `lazyOnload`, `worker`.

Inline scripts need an `id`. For Google Analytics, use `@next/third-parties/google`.

## Hydration Errors

Common causes and fixes:

| Cause | Fix |
|---|---|
| `new Date()`, `Math.random()` in server render | Move to `useEffect` or wrap in `<Suspense>` + `await connection()` |
| Browser API at render time (`window`, `localStorage`) | Move to `useEffect`; guard with `typeof window !== 'undefined'` |
| Different content server vs client | Use `useState(false)` + `useEffect(() => setMounted(true))`, render conditionally |
| Invalid HTML (e.g. `<div>` inside `<p>`) | Fix the HTML |
| Browser extension injecting | `<html suppressHydrationWarning>` on the root |

## Suspense Boundaries

`useSearchParams()`, `usePathname()`, and other navigation hooks in Client Components bail out to CSR for the whole subtree **unless** they're inside a `<Suspense>` boundary. Always wrap the deepest reasonable parent in Suspense.

## Self-Hosting (when not on Vercel)

```ts
// next.config.ts — for Docker
const nextConfig: NextConfig = { output: 'standalone' }
```

For multi-instance ISR, configure a custom cache handler (Redis-backed). `output: 'export'` produces a static-only site (no Server Actions, no `next/image` optimization without a custom loader).

## Self-Audit Checklist

- [ ] `'use client'` only on leaves that need it
- [ ] No `async` Client Components
- [ ] No `Date`/`Map`/`Set`/function props across the boundary (Server Actions excepted)
- [ ] `Promise.all` for independent fetches
- [ ] Slow parts inside `<Suspense>` with real skeletons
- [ ] `'use cache'` (Next 16+) on cacheable async work; no blanket `force-dynamic`
- [ ] `next/link` for internal nav, `next/image` for images, `next/font` for fonts
- [ ] `optimizePackageImports` lists every icon/UI library you import
- [ ] `remotePatterns` set for every remote image host
- [ ] `error.tsx`, `loading.tsx`, `not-found.tsx` where it matters
- [ ] No `try/catch` around `redirect()` / `notFound()` / `forbidden()` / `unauthorized()`
