# React Performance Reference

Performance traps, ranked by impact. Distilled from Vercel Engineering's 70 rules.

## 1. Eliminate Waterfalls (CRITICAL — 2–10× wins)

### Promise.all for independent operations

```typescript
// BAD: 3 round trips
const user = await fetchUser()
const posts = await fetchPosts()
const comments = await fetchComments()

// GOOD: 1 round trip
const [user, posts, comments] = await Promise.all([
  fetchUser(), fetchPosts(), fetchComments(),
])
```

### Cheap sync condition before await

If a flag or local value already disqualifies the path, check it before paying network cost.

```typescript
// BAD: await even when feature is disabled
const enabled = await getRemoteFlag()
if (!enabled) return null
const data = await fetchHeavy()

// GOOD: cheap local check first
if (!process.env.FEATURE_X) return null
const data = await fetchHeavy()
```

### Defer await into the branch that needs it

```typescript
// BAD: await regardless
const user = await getUser()
return mode === 'admin' ? <Admin user={user} /> : <Public />

// GOOD: await only when used
return mode === 'admin' ? <Admin user={await getUser()} /> : <Public />
```

### Parallel dependent fetches with per-item Promise.all

```typescript
// BAD: serial inside the loop
const enriched = []
for (const item of items) {
  const meta = await getMeta(item.id)
  enriched.push({ ...item, meta })
}

// GOOD: kick off all in parallel
const enriched = await Promise.all(
  items.map(async (item) => ({ ...item, meta: await getMeta(item.id) }))
)
```

### Start promises early in API routes / Server Components

```typescript
// app/api/posts/route.ts
export async function GET(req: NextRequest) {
  const postsP = db.posts.findMany()       // start now
  const userP  = getCurrentUser(req)       // start now
  const [posts, user] = await Promise.all([postsP, userP])
  return NextResponse.json({ posts, user })
}
```

### Stream with Suspense for slow + slower

Don't gate the fast section on the slow one. Wrap slow regions in `<Suspense>`:

```tsx
<Suspense fallback={<HeaderSkeleton />}>  <Header /></Suspense>
<Suspense fallback={<FeedSkeleton />}>    <Feed /></Suspense>
```

## 2. Bundle-Size Traps (CRITICAL)

### Barrel imports are expensive

`lucide-react`, `@mui/material`, `@radix-ui/*`, `lodash`, `date-fns`, `react-icons`, `@headlessui/react`, `rxjs`, `ramda`, `react-use` re-export thousands of modules from one entry. A `import { Bell } from 'lucide-react'` loads ~1,500 modules and adds 200–800 ms of cold-start time.

**Next.js fix:**
```ts
// next.config.ts
const nextConfig: NextConfig = {
  experimental: {
    optimizePackageImports: ['lucide-react', '@mui/material', '@radix-ui/react-icons', /* … */],
  },
}
```

This rewrites your imports to deep paths at build time, preserving types and autocomplete.

**Non-Next fix:** import deep paths directly: `import Button from '@mui/material/Button'`. Beware some libs (e.g., `lucide-react`) don't ship `.d.ts` for deep paths.

### Statically-analyzable paths

Bundlers can only trace static imports. Dynamic `import(`./foo/${name}`)` includes **every** file under `./foo/`. Either enumerate explicitly or restructure.

### Dynamic imports for heavy components

```tsx
import dynamic from 'next/dynamic'

const Editor = dynamic(() => import('./Editor'), {
  loading: () => <p>Loading editor…</p>,
  ssr: false,    // when it uses browser APIs
})
```

Use when: a leaf component (charts, editors, modals) ships a heavy dep, but most users won't open it.

### Conditional loading

Don't import a feature module at the top of the file if the feature might be disabled:

```tsx
// BAD: ships even when disabled
import { HeavyFeature } from './heavy'
function App({ enabled }) { return enabled ? <HeavyFeature /> : null }

// GOOD
const HeavyFeature = dynamic(() => import('./heavy'))
function App({ enabled }) { return enabled ? <HeavyFeature /> : null }
```

### Defer third-party scripts

Analytics, logging, A/B test SDKs almost never need to block the first render. Load after hydration:

```tsx
import Script from 'next/script'
<Script src="https://example.com/analytics.js" strategy="afterInteractive" />
```

### Preload on hover/focus

For navigations users *might* take, fetch the next route's data on hover:

```tsx
<a onMouseEnter={() => preloadPost(id)} onFocus={() => preloadPost(id)} href={`/posts/${id}`}>…</a>
```

## 3. Server-Side Performance (HIGH)

### React.cache() for per-request dedup

Calling the same `getUser(id)` from 5 components shouldn't run 5 queries.

```tsx
import { cache } from 'react'
export const getUser = cache(async (id: string) => db.user.findUnique({ where: { id } }))
```

`cache()` dedupes within a single request. For cross-request caching, use `'use cache'` (Next 16+) or an LRU.

### LRU for cross-request, in-memory caching

```tsx
import { LRUCache } from 'lru-cache'
const cache = new LRUCache<string, User>({ max: 1000, ttl: 60_000 })

export async function getUserCached(id: string) {
  const hit = cache.get(id)
  if (hit) return hit
  const user = await db.user.findUnique({ where: { id } })
  if (user) cache.set(id, user)
  return user
}
```

**Caveat:** in-memory caches don't survive serverless cold starts and don't share across instances. For that, use Redis / Vercel KV / a `'use cache: remote'` profile.

### Hoist static I/O to module level

Fonts, logos, design tokens — files that never change at runtime — should be read **once at module load**, not per-request:

```tsx
// BAD — every request hits the disk
async function getFont() { return fs.promises.readFile('./font.woff2') }

// GOOD — cached at module load
const FONT = await fs.promises.readFile('./font.woff2')
export function font() { return FONT }
```

### Minimize props serialized to Client Components

Every prop crosses the RSC boundary as JSON. Don't pass the whole DB record if the client only needs `name` and `id`:

```tsx
// BAD: ships everything (60 fields)
<ClientCard user={user} />

// GOOD: pick what's needed
<ClientCard user={{ id: user.id, name: user.name, avatar: user.avatarUrl }} />
```

### Restructure to parallelize nested fetches

```tsx
// BAD — page awaits user, then layout awaits posts
async function Page() { const user = await getUser(); return <Layout user={user} /> }
async function Layout({ user }) { const posts = await getPosts(user.id); … }

// GOOD — start both in the page
async function Page() {
  const [user, posts] = await Promise.all([getUser(), getCurrentUserPosts()])
  return <Layout user={user} posts={posts} />
}
```

### `after()` for non-blocking server work

Log writes, analytics, cache warming — work whose result the response doesn't depend on:

```tsx
import { after } from 'next/server'
export default async function Page() {
  after(() => logPageView())   // runs after response is sent
  return <div>Hi</div>
}
```

## 4. Client-Side Data (MEDIUM-HIGH)

### SWR / TanStack Query for client fetches

Built-in dedup, focus refetch, stale-while-revalidate. Plain `useEffect(fetch)` re-runs on every mount and doesn't share cache across components.

```tsx
'use client'
import useSWR from 'swr'
function Posts() {
  const { data, error, isLoading } = useSWR('/api/posts', (u) => fetch(u).then(r => r.json()))
  // …
}
```

### Deduplicate global event listeners

If 12 components subscribe to `window.resize`, dedup once at app root and broadcast via context or a small store.

### Passive event listeners on scroll/touch

```tsx
useEffect(() => {
  const onScroll = () => { /* … */ }
  window.addEventListener('scroll', onScroll, { passive: true })
  return () => window.removeEventListener('scroll', onScroll)
}, [])
```

`{ passive: true }` lets the browser scroll without waiting for your handler — keeps scrolling smooth.

### localStorage discipline

Version your schema (`{ v: 2, … }`); migrate or drop on mismatch. Keep payloads small — 5 MB cap is shared with everything.

## 5. Re-render Optimization (MEDIUM)

### Don't subscribe to state only used in callbacks

```tsx
// BAD — re-renders on every count change
function Button() {
  const count = useStore((s) => s.count)
  return <button onClick={() => alert(count)}>+</button>
}

// GOOD — read on click, no subscription
function Button() {
  const get = useStore.getState
  return <button onClick={() => alert(get().count)}>+</button>
}
```

### Derive state during render, not in `useEffect`

```tsx
// BAD — extra render + sync bugs
const [filtered, setFiltered] = useState<Item[]>([])
useEffect(() => setFiltered(items.filter(p)), [items])

// GOOD
const filtered = items.filter(p)
```

If the computation is expensive: `useMemo(() => items.filter(p), [items])`.

### Subscribe to derived booleans, not raw values

```tsx
// BAD — re-renders on any items change
const items = useStore((s) => s.items)
const hasItems = items.length > 0

// GOOD — re-renders only when boolean flips
const hasItems = useStore((s) => s.items.length > 0)
```

### Functional setState for stable callbacks

```tsx
// BAD — callback identity changes every count update
const [count, setCount] = useState(0)
const inc = useCallback(() => setCount(count + 1), [count])

// GOOD
const inc = useCallback(() => setCount(c => c + 1), [])
```

### Lazy state init for expensive defaults

```tsx
// BAD — runs on every render
const [tree] = useState(buildBigTree())

// GOOD — runs once
const [tree] = useState(() => buildBigTree())
```

### Primitive dependencies in effects

```tsx
// BAD — re-runs every render (new object identity)
useEffect(() => sync({ id, scope }), [{ id, scope }])

// GOOD — primitives compared by value
useEffect(() => sync({ id, scope }), [id, scope])
```

### Don't define components inside components

```tsx
// BAD — remounts Inner every render, loses state
function Outer() {
  function Inner() { return <div /> }
  return <Inner />
}

// GOOD
function Inner() { return <div /> }
function Outer() { return <Inner /> }
```

### `startTransition` for non-urgent updates

```tsx
import { useTransition } from 'react'
const [isPending, startTransition] = useTransition()

function onFilterChange(v: string) {
  setInput(v)                              // urgent (input is responsive)
  startTransition(() => setFilter(v))      // non-urgent (the list catches up)
}
```

`useDeferredValue` is the prop-version of the same idea: `const deferred = useDeferredValue(value)`.

### Refs for transient values that don't render

Mouse coords, scroll positions during a drag, timers — anything you read but don't render directly should be a ref, not state.

## 6. Rendering Performance (MEDIUM)

- **Animate `div` wrappers, not SVG roots.** SVGs are expensive to invalidate.
- **`content-visibility: auto`** for long off-screen lists — browser skips them.
- **Hoist static JSX** out of the render function (assign to a `const` at module scope).
- **Reduce SVG coordinate precision** — `0.12345` → `0.12`. Smaller files, fewer bytes parsed.
- **Inline script for client-only data** to avoid hydration flicker (e.g., theme).
- **`suppressHydrationWarning` on expected mismatches** (theme attribute on `<html>`).
- **Resource hints**: `<link rel="preconnect" href="…">`, `<link rel="preload" as="font" href="…">` via React's `<link>` or `<head>`.
- **`defer` or `async` on every `<script>` tag.**

## 7. JavaScript Performance (LOW-MEDIUM)

- **Group DOM/CSS changes** — one class swap beats 5 style assignments.
- **`Map`/`Set` for O(1) lookups** when you'll query 10+ times.
- **Cache `obj.deeply.nested.thing` to a local in tight loops.**
- **Cache function results in a module-level `Map`** when input → output is stable.
- **`toSorted()`/`toReversed()`** for immutability without manual cloning.
- **`flatMap` to map+filter in one pass.**
- **`requestIdleCallback`** for non-critical work after first paint.
- **Hoist `RegExp` literals out of hot loops.**

## 8. Advanced (LOW)

- **`useEffectEvent`** for stable event handlers that read latest state without subscribing.
- **Refs for event handlers** that don't need to invalidate parents.
- **Init-once** for app-load setup (analytics, error reporters): guard with a module-level `let inited = false`.
- **`useLatest` ref pattern** for stable callback refs that always see latest state.

## Self-Audit Checklist

- [ ] No two `await`s on independent values in sequence — `Promise.all` instead
- [ ] `optimizePackageImports` configured for every icon/UI lib
- [ ] No client `fetch` in `useEffect` without SWR/Query
- [ ] `React.cache()` on per-request shared reads
- [ ] No state subscriptions only used in callbacks
- [ ] No effects deriving state — derive during render
- [ ] No components defined inside other components
- [ ] No object/array literals in effect dep arrays
- [ ] Slow regions wrapped in `<Suspense>` so the fast ones stream
