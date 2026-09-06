# Next.js + TypeScript Patterns

> **Scope**: App Router types, params, searchParams, Server Actions, RSC/client boundaries, metadata  
> **Consult when**: Writing Next.js App Router code, debugging server/client issues  
> **See also**: → `data-fetching-and-api-types.md`, → `forms-and-validation.md`, → `debugging-checklists.md` (hydration)

---

## Version Assumptions

This file targets **Next.js 15+** (App Router). Key version differences:
- **15+**: `params` and `searchParams` are `Promise` — must `await`
- **16+**: Cache Components with `"use cache"` directive (opt-in via `cacheComponents: true`); `middleware.ts` renamed to `proxy.ts` (Node.js runtime)
- **14**: `params` is a plain object (no await needed)

When version is ambiguous, **ask the user**.

---

## Page & Layout Props [HARD RULE]

```tsx
// Next.js 15+: params and searchParams are Promises
interface PageProps {
  params: Promise<{ slug: string }>
  searchParams: Promise<{ q?: string; page?: string }>
}

export default async function Page({ params, searchParams }: PageProps) {
  const { slug } = await params
  const { q, page } = await searchParams

  // ⚠️ searchParams values are ALWAYS string | string[] | undefined
  // Never trust without parsing
  const pageNum = Number(page) || 1
}
```

**Common bug**: Not awaiting params in Next.js 15+ → type error or runtime failure.

### Generated route type helpers (15.5+) [DEFAULT]

Next.js generates global, route-string-typed helpers — prefer them over hand-written Props interfaces:

```tsx
// No import — globally available, keys typed from the actual route
export default async function Page(props: PageProps<'/blog/[slug]'>) {
  const { slug } = await props.params   // slug: string, typo in route string = type error
}
```

`LayoutProps<'/dashboard'>` and `RouteContext<'/api/users/[id]'>` cover layouts and Route Handlers.

---

## Server vs Client Boundary [HARD RULE]

- Server Components are the **default**. Only add `"use client"` when needed.
- Push `"use client"` **as deep as possible**.
- Props crossing the boundary **must be RSC-serializable** — which is NOT plain JSON.

| ✅ Can cross boundary | ❌ Cannot cross |
|----------------------|----------------|
| Primitives (incl. `bigint`, `undefined`, `NaN`) | Functions that aren't Server Functions |
| Plain objects, arrays | Class instances (ORM rows, `Decimal`, domain models) |
| `Date`, `Map`, `Set`, TypedArray, `ArrayBuffer` | Symbols (unless `Symbol.for`) |
| Promises — resolve on the client with `use()` | Objects with custom prototypes |
| JSX, Server Functions (`'use server'`) | |

`Date`, `Map`, and `Set` cross the App Router boundary intact — do NOT `.toISOString()` them for serialization's sake. The strict JSON-only rule belongs to the **Pages Router** (`getServerSideProps`), where `Date`/`Map`/`Set`/`undefined` must be converted.

```tsx
// ✅ Server component fetches, client island handles interaction
export default async function ProductPage({ params }: PageProps) {
  const { id } = await params
  const product = await getProduct(id)
  return (
    <article>
      <h1>{product.name}</h1>                        {/* server */}
      <AddToCartButton productId={product.id} />     {/* client island */}
    </article>
  )
}
```

### Preventing server-only leaks [HARD RULE]

```ts
// lib/db.ts
import 'server-only'  // compile error if imported from client component
export async function getUser(id: string) { ... }
```

---

## Server Actions [DEFAULT]

Always validate FormData with Zod. Return a typed state object.

```tsx
'use server'

import { z } from 'zod'

const createPostSchema = z.object({
  title: z.string().min(1, 'Required').max(200),
  content: z.string().min(1, 'Required'),
})

interface ActionState {
  success: boolean
  message: string
  errors?: Record<string, string[]>
}

export async function createPost(prev: ActionState, formData: FormData): Promise<ActionState> {
  const parsed = createPostSchema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
  })

  if (!parsed.success) {
    return { success: false, message: 'Validation failed', errors: z.flattenError(parsed.error).fieldErrors }
  }

  await db.post.create({ data: parsed.data })
  return { success: true, message: 'Created' }
}
```

---

## Route Handlers [DEFAULT]

```tsx
import { NextRequest, NextResponse } from 'next/server'

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params
  const user = await getUser(id)
  if (!user) return NextResponse.json({ error: 'Not found' }, { status: 404 })
  return NextResponse.json(user)
}
```

## Metadata [DEFAULT]

```tsx
import { Metadata } from 'next'

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params
  const post = await getPost(slug)
  return { title: post.title, openGraph: { title: post.title, images: [post.thumbnail] } }
}
```

---

## Cache Components (Next.js 16) [DEFAULT for 16+]

With `cacheComponents: true` in `next.config.ts`, **nothing is cached implicitly** — dynamic code runs per-request until you opt in with `'use cache'`:

```tsx
import { cacheLife, cacheTag } from 'next/cache'

async function getPosts() {
  'use cache'          // works at function, component, or file level
  cacheLife('hours')   // profile: seconds | minutes | hours | days | weeks | max | custom
  cacheTag('posts')    // enables targeted invalidation
  const res = await fetch('https://api.example.com/posts')
  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return postsSchema.parse(await res.json())
}
```

Arguments and closed-over values automatically form the cache key — different args, different entry.

**Invalidation — prefer tags over paths**:

| API | Where | Behavior |
|-----|-------|----------|
| `revalidateTag('posts', 'max')` | anywhere | SWR — serves stale, refreshes in background. 16 requires the 2nd argument |
| `updateTag('posts')` | Server Actions only | expires + refreshes immediately — read-your-own-writes |
| `revalidatePath('/blog')` | anywhere | blunt path-level invalidation |

**PPR rule**: components reading runtime APIs (`cookies()`, `headers()`, `searchParams`) must sit inside `<Suspense>`, or the build fails with "Uncached data was accessed outside of `<Suspense>`". If a cached function needs a runtime value, extract it first and pass it as an argument — it joins the cache key:

```tsx
async function Profile() {
  const sessionId = (await cookies()).get('session')?.value
  return <CachedProfile sessionId={sessionId} />   // runtime read outside the cache
}
```

## Common Bug Patterns

- Not awaiting `params`/`searchParams` (Next.js 15+)
- Trusting `searchParams` without validation (always `string | string[] | undefined`)
- `formData.get('x') as string` — could be `null` or `File`
- `"use client"` at page level → entire tree becomes client
- Passing plain callbacks (non-Server-Function) across the server/client boundary
- Class instances (ORM rows, `Decimal`) in cross-boundary Props → serialization failure
- Converting `Date` to string "for serialization" in the App Router → unnecessary, loses the type
- Server-only imports (db, API keys) in client components

## Review Checklist

- [ ] `params` and `searchParams` awaited (Next.js 15+)
- [ ] searchParams validated, not trusted
- [ ] Server Actions validate FormData with Zod
- [ ] `"use client"` only where needed, as deep as possible
- [ ] Cross-boundary Props are RSC-serializable (no plain callbacks or class instances)
- [ ] `import 'server-only'` on sensitive modules
- [ ] 16+: caching is explicit `'use cache'` opt-in; runtime APIs wrapped in `<Suspense>`; mutations needing immediate reads use `updateTag`

---

## searchParams Deep Dive [HARD RULE: always validate]

searchParams values are ALWAYS `string | string[] | undefined`. Never trust without parsing.

```tsx
// ✅ Full validation with Zod
const searchSchema = z.object({
  q: z.string().optional().default(''),
  page: z.coerce.number().int().positive().optional().default(1),
  sort: z.enum(['name', 'date', 'price']).optional().default('date'),
  categories: z.union([z.string(), z.array(z.string())]).optional()
    .transform(v => (Array.isArray(v) ? v : v ? [v] : [])),
})

export default async function SearchPage({ searchParams }: PageProps) {
  const raw = await searchParams
  const { q, page, sort, categories } = searchSchema.parse(raw)
  // q: string, page: number, sort: 'name'|'date'|'price', categories: string[]
  // All validated and typed correctly

  const results = await searchProducts({ q, page, sort, categories })
  return <ProductGrid results={results} />
}
```

**Common bug**: `searchParams.page` used as number directly → it's a `string`. Use `z.coerce.number()` or `Number()`.

---

## useOptimistic with Server Actions [SITUATIONAL]

**When to use**: Mutation where instant UI feedback is critical (like, bookmark, toggle).  
**Tradeoff**: UI updates before server confirms. If server fails, must revert. Adds complexity.

```tsx
'use client'

import { useOptimistic, useTransition } from 'react'
import { toggleBookmark } from '@/actions/bookmarks'

interface BookmarkButtonProps {
  productId: string
  isBookmarked: boolean
}

function BookmarkButton({ productId, isBookmarked }: BookmarkButtonProps) {
  const [optimistic, setOptimistic] = useOptimistic(isBookmarked)
  const [isPending, startTransition] = useTransition()

  const handleToggle = () => {
    startTransition(async () => {
      setOptimistic(!optimistic)  // instant UI update
      await toggleBookmark(productId)  // if this fails, React reverts
    })
  }

  return (
    <button onClick={handleToggle} aria-pressed={optimistic} disabled={isPending}>
      {optimistic ? '★ Bookmarked' : '☆ Bookmark'}
    </button>
  )
}
```

---

## Proxy (formerly Middleware) [SITUATIONAL]

**When to use**: Auth checks, redirects, headers, geolocation-based routing.

**Next.js 16 renamed `middleware.ts` → `proxy.ts`.** Same role — an explicit network boundary in front of routes — but the runtime changed:

| Version | File | Runtime | Node.js APIs |
|---------|------|---------|--------------|
| ≤ 15 | `middleware.ts` | Edge | ❌ Web APIs only |
| 16+ | `proxy.ts` | Node.js (not configurable, Edge unsupported) | ✅ |

Codemod: `npx @next/codemod middleware-to-proxy`. `middleware.ts` still works in 16 but is deprecated.

```tsx
// proxy.ts (Next.js 16) — for ≤15 name it middleware.ts and export `middleware`
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function proxy(request: NextRequest) {
  const token = request.cookies.get('session')?.value

  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    const loginUrl = new URL('/login', request.url)
    loginUrl.searchParams.set('redirect', request.nextUrl.pathname)
    return NextResponse.redirect(loginUrl)
  }

  // Add custom headers
  const response = NextResponse.next()
  response.headers.set('x-pathname', request.nextUrl.pathname)
  return response
}

export const config = {
  matcher: ['/dashboard/:path*', '/settings/:path*'],
}
```

**[HARD RULE]**: `middleware.ts` (≤15, Edge runtime) cannot use Node.js APIs (`fs`, `crypto.createHash`, etc.) — Web APIs only. In 16+ `proxy.ts` runs on Node so that restriction is gone; keep it thin anyway — heavy work belongs in Route Handlers or Server Components.

---

## Safe Recommendation Template

When helping with Next.js typing:
1. What Next.js version? → Determines if params is Promise or object
2. Is this server or client code? → Different APIs available
3. Is searchParams used? → Always validate with Zod
4. Is FormData involved? → Always parse, never `as string`
5. Crossing server/client boundary? → Check serialization
