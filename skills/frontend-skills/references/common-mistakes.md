# Common Mistakes (Before/After)

The mistakes that show up most often in AI-generated and human-written React/Next.js/Tailwind code. Each is sourced from real review feedback and the failures observed in baseline testing for this skill.

## 1. `export const dynamic = 'force-dynamic'` as a hammer

**Symptom:** The page reads `cookies()` once, so the agent slaps `force-dynamic` on it and disables every optimization for the whole route.

**Why bad:** Next.js 16 Cache Components let static, cached, and dynamic content coexist. `force-dynamic` makes everything dynamic. The static shell and cacheable lists become re-rendered per request.

**Before:**
```tsx
// app/dashboard/page.tsx
export const dynamic = 'force-dynamic'

export default async function Page() {
  const user  = await db.user.findUnique({ where: { id: getUserId() } })
  const posts = await db.posts.findMany({ where: { authorId: user.id } })
  const notifications = await fetchNotifications()
  return <Dashboard user={user} posts={posts} notifications={notifications} />
}
```

**After (Next.js 16+ with `cacheComponents: true`):**
```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react'

export default async function Page() {
  const userId = (await cookies()).get('userId')!.value
  return (
    <>
      <CachedProfile userId={userId} />          {/* cached */}
      <CachedPosts userId={userId} />            {/* cached */}
      <Suspense fallback={<NotificationsSkeleton />}>
        <Notifications userId={userId} />         {/* dynamic, streams */}
      </Suspense>
    </>
  )
}

async function CachedProfile({ userId }: { userId: string }) {
  'use cache'
  cacheLife('hours')
  cacheTag(`user-${userId}`)
  const user = await db.user.findUnique({ where: { id: userId } })
  return <ProfileCard user={user!} />
}

async function CachedPosts({ userId }: { userId: string }) {
  'use cache'
  cacheLife('minutes')
  cacheTag(`user-posts-${userId}`)
  const posts = await db.posts.findMany({ where: { authorId: userId } })
  return <PostsList posts={posts} />
}

async function Notifications({ userId }: { userId: string }) {
  const items = await db.notifications.findMany({ where: { userId, read: false } })
  return <NotificationsList items={items} />
}
```

## 2. Barrel imports without `optimizePackageImports`

**Symptom:** Three lucide-react imports across the codebase, no `next.config.ts` optimization, dev boot is slow and prod cold start lags.

**Before:**
```tsx
// next.config.ts
const nextConfig: NextConfig = {
  images: { remotePatterns: [{ protocol: 'https', hostname: 'cdn.example.com' }] },
}

// components/header.tsx
import { Bell, User, Settings } from 'lucide-react'

// components/sidebar.tsx
import { Home, Search } from 'lucide-react'
```

**After:**
```tsx
// next.config.ts
const nextConfig: NextConfig = {
  images: { remotePatterns: [{ protocol: 'https', hostname: 'cdn.example.com' }] },
  experimental: {
    optimizePackageImports: ['lucide-react', '@radix-ui/react-icons'],
  },
}
```

No code changes needed in the imports. Next.js rewrites them to deep paths at build time. **15–70% faster dev boot, 28% faster builds, 40% faster cold starts**, per the Vercel benchmark.

## 3. `<a href="/route">` for internal navigation

**Symptom:** Internal link uses a plain anchor tag. Full page reload on click, no prefetch.

**Before:**
```tsx
<a href={`/posts/${post.id}`} className="hover:underline">{post.title}</a>
```

**After:**
```tsx
import Link from 'next/link'
<Link href={`/posts/${post.id}`} className="hover:underline">{post.title}</Link>
```

`<Link>` prefetches the route on hover/viewport-enter, then does client-side nav on click. Plain `<a>` is correct for **external** links and explicit "open in new tab".

## 4. `<img>` instead of `<Image>`

**Before:**
```tsx
<img src="/hero.png" alt="Hero" className="w-full" />
```

**After:**
```tsx
import Image from 'next/image'
import hero from './hero.png'        // local image — dimensions inferred
<Image src={hero} alt="Hero" placeholder="blur" priority className="w-full h-auto" />

// OR remote
<div className="relative aspect-[16/9] w-full">
  <Image src="https://cdn.example.com/hero.png" alt="Hero" fill sizes="100vw" priority className="object-cover" />
</div>
```

Layout-shift-free, lazy by default (except `priority`), WebP/AVIF served when the browser supports it, multiple sizes generated.

## 5. Async Client Component

**Symptom:** A client component is `async`. Runtime error on first render.

**Before:**
```tsx
'use client'
export default async function Profile({ id }: { id: string }) {
  const user = await getUser(id)
  return <div>{user.name}</div>
}
```

**After:** Fetch in the server parent, pass plain data down.
```tsx
// page.tsx (server)
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const user = await getUser(id)
  return <ProfileClient user={user} />
}

// ProfileClient.tsx
'use client'
export function ProfileClient({ user }: { user: User }) {
  return <div>{user.name}</div>
}
```

## 6. Passing a `Date` across the boundary

**Symptom:** A `Date` is passed to a Client Component as a prop. Looks fine until the client tries to call `.getFullYear()` and crashes.

**Before:**
```tsx
// page.tsx (server)
export default async function Page() {
  const post = await getPost()
  return <PostCard createdAt={post.createdAt} />
}

// PostCard.tsx (client)
'use client'
export function PostCard({ createdAt }: { createdAt: Date }) {
  return <span>{createdAt.getFullYear()}</span>   // crash: getFullYear is not a function
}
```

**After:**
```tsx
// page.tsx (server)
return <PostCard createdAt={post.createdAt.toISOString()} />

// PostCard.tsx (client)
'use client'
export function PostCard({ createdAt }: { createdAt: string }) {
  return <span>{new Date(createdAt).getFullYear()}</span>
}
```

Same rule for `Map`, `Set`, class instances, functions (except Server Actions).

## 7. Sequential awaits when they could be parallel

**Before:**
```tsx
const user     = await getUser()
const posts    = await getPosts()
const comments = await getComments()
```

**After:**
```tsx
const [user, posts, comments] = await Promise.all([getUser(), getPosts(), getComments()])
```

2–3× latency reduction. Only sequence when one truly depends on another.

## 8. `try/catch` around `redirect()` or `notFound()`

**Symptom:** A server action's redirect doesn't fire. User clicks Save, sees "Failed" toast.

**Before:**
```tsx
'use server'
import { redirect } from 'next/navigation'

export async function createPost(formData: FormData) {
  try {
    const post = await db.post.create({ data: { title: formData.get('title') } })
    redirect(`/posts/${post.id}`)   // redirect() throws internally — caught below
  } catch (error) {
    return { error: 'Failed to create post' }
  }
}
```

**After (redirect outside try/catch):**
```tsx
export async function createPost(formData: FormData) {
  let post
  try {
    post = await db.post.create({ data: { title: formData.get('title') } })
  } catch {
    return { error: 'Failed to create post' }
  }
  redirect(`/posts/${post.id}`)
}
```

**Or (re-throw):**
```tsx
import { unstable_rethrow } from 'next/navigation'
export async function createPost(formData: FormData) {
  try {
    const post = await db.post.create({ data: { title: formData.get('title') } })
    redirect(`/posts/${post.id}`)
  } catch (error) {
    unstable_rethrow(error)
    return { error: 'Failed to create post' }
  }
}
```

## 9. Boolean prop proliferation

**Before:**
```tsx
<Composer isThread channelId="c_1" />
<Composer isDMThread dmId="d_1" />
<Composer isEditing />
<Composer isForwarding />
```

**After:** Either compound components or explicit variants.
```tsx
<ChannelComposer />
<ThreadComposer channelId="c_1" />
<EditComposer />
<ForwardComposer />
```

See `composition.md` for the full breakdown.

## 10. Inline conditional class strings repeated everywhere

**Before:**
```tsx
<button
  className={
    isActive
      ? "bg-blue-500 text-white rounded-md px-3 py-2 text-sm hover:bg-blue-600"
      : "bg-white text-neutral-700 border border-neutral-200 rounded-md px-3 py-2 text-sm hover:bg-neutral-50"
  }
/>
```

**After (`cn` + `cva`):**
```ts
const button = cva('inline-flex items-center rounded-md px-3 py-2 text-sm', {
  variants: {
    intent: {
      primary:   'bg-blue-500 text-white hover:bg-blue-600',
      secondary: 'bg-white text-neutral-700 border border-neutral-200 hover:bg-neutral-50',
    },
  },
})

<button className={button({ intent: isActive ? 'primary' : 'secondary' })} />
```

## 11. `notFound()` mentioned in a comment but not called

**Before:**
```tsx
const user = await db.user.findUnique({ where: { id } })
if (!user) {
  // Could throw notFound() from next/navigation
  return <main>User not found</main>
}
```

**After:**
```tsx
import { notFound } from 'next/navigation'

const user = await db.user.findUnique({ where: { id } })
if (!user) notFound()
```

The closest `not-found.tsx` renders, the response status is 404, and you don't reimplement layout for the error.

## 12. Hardcoded current-user ID in source

**Symptom:** A page hardcodes `const CURRENT_USER_ID = "u_1"` instead of reading from session.

**Why bad:** It's not "mock data" — it's a stub that ships. Real auth comes from `cookies()` or `headers()`. If you must stub, isolate it in one place that's obvious to swap.

**Before:**
```tsx
const CURRENT_USER_ID = "u_1"
export default async function Page() {
  const user = await db.user.findUnique({ where: { id: CURRENT_USER_ID } })
  // …
}
```

**After:**
```tsx
import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'

export default async function Page() {
  const sessionCookie = (await cookies()).get('session')?.value
  if (!sessionCookie) redirect('/login')
  const session = await verifySession(sessionCookie)
  const user = await db.user.findUnique({ where: { id: session.userId } })
  // …
}
```

## 13. `useEffect` to derive state

**Before:**
```tsx
const [filtered, setFiltered] = useState<Item[]>([])
useEffect(() => setFiltered(items.filter(i => i.active)), [items])
```

**After:**
```tsx
const filtered = items.filter(i => i.active)
// If expensive: useMemo(() => items.filter(i => i.active), [items])
```

Derived state in `useState`+`useEffect` causes an extra render and a sync hazard. Compute during render.

## 14. Defining components inside other components

**Before:**
```tsx
function Page() {
  function Card({ x }: { x: number }) { return <div>{x}</div> }
  return <Card x={1} />
}
```

**After:**
```tsx
function Card({ x }: { x: number }) { return <div>{x}</div> }
function Page() { return <Card x={1} /> }
```

Inner components remount on every parent render — losing state, restarting effects, blowing memoization.

## 15. Object/array literals as effect dependencies

**Before:**
```tsx
useEffect(() => sync({ id, scope }), [{ id, scope }])
// re-runs every render — new object identity each time
```

**After:**
```tsx
useEffect(() => sync({ id, scope }), [id, scope])
```

Primitive dependencies compare by value. Object literals don't.

## 16. Mismatched types across the data model

**Symptom:** `Post.createdAt: Date` but `Notification.createdAt: string`. Half the formatters take `Date`, half take `string`, all are forced to handle both.

**Fix:** Pick one (string ISO is friendliest for boundary-crossing) and make the database layer normalize on the way out. The codebase has *one* shape for timestamps.

## 17. Tailwind without `dark:` variants

**Before:**
```tsx
<div className="bg-white text-neutral-900 border border-neutral-200 p-4 rounded-lg">
```

**After:**
```tsx
<div className="bg-white dark:bg-neutral-950 text-neutral-900 dark:text-neutral-50 border border-neutral-200 dark:border-neutral-800 p-4 rounded-lg">

// or better — semantic tokens
<div className="bg-bg-elevated text-fg border-border p-4 rounded-lg">
```

White cards survive a dark-mode toggle as bright rectangles. Pair every color.
