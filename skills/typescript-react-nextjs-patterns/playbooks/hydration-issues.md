# Playbook: Hydration Issues

> **Scope**: SSR/CSR mismatch diagnosis and fixes in Next.js  
> **Consult when**: "Hydration failed", "Text content does not match", or UI flicker after load  
> **See also**: → `rules/nextjs-typescript.md`, → `rules/performance-and-accessibility.md`

---

## What Is a Hydration Mismatch?

1. Server renders HTML
2. Browser receives HTML (fast first paint)
3. React "hydrates" — attaches event handlers and compares server HTML with client render
4. **If they differ → hydration error.** React can't reconcile.

---

## Step 0 (React 19+): Read the Diff

React 19 replaced the pile of vague warnings with a single error containing a **server/client HTML diff** that names the exact mismatched node — read it before diagnosing anything. React 19 also skips unexpected extension-injected tags in `<head>`/`<body>` during hydration, so extension noise is mostly a React 18 legacy problem.

---

## Diagnosis Flowchart

```
Is the mismatched content...
├─ Date/time dependent?        → Defer to useEffect
├─ Random ID for an element?   → useId — SSR-stable by design. Don't seed, don't defer.
├─ Other random values?        → Seed-based or defer to useEffect
├─ Browser-API dependent?      → useSyncExternalStore (server snapshot) or useEffect / dynamic import
│  (window, matchMedia, localStorage, navigator)
├─ Theme / dark mode?          → Pre-hydration inline script + suppressHydrationWarning (Pattern 5)
├─ User-specific? (auth)       → <Suspense> boundary, or defer to useEffect
├─ From a browser extension?   → React 19 skips these. On 18: test in incognito. Not your bug.
└─ From CSS-in-JS?             → Configure SSR extraction for your library
```

---

## Fix Patterns

### Pattern 1: Defer to useEffect (most common)

```tsx
function ClientTimestamp() {
  const [time, setTime] = useState<string | null>(null)

  useEffect(() => {
    setTime(new Date().toLocaleString())
  }, [])

  if (!time) return <span aria-busy="true">Loading...</span>
  return <time>{time}</time>
}
```

**Why this works**: `useState(null)` on server → renders "Loading...".  
Same `null` on client during hydration → matches. Then `useEffect` runs client-only.

### Pattern 2: dynamic import with ssr: false

```tsx
import dynamic from 'next/dynamic'

const Chart = dynamic(() => import('./Chart'), {
  ssr: false,
  loading: () => <div aria-busy="true">Loading chart...</div>,
})
```

**When to use**: Entire component depends on browser APIs (canvas, WebGL, IntersectionObserver).

**App Router constraint**: `ssr: false` inside a Server Component is a build error — the `dynamic()` call must live in a `"use client"` wrapper component.

### Pattern 3: Suspense boundary for user-specific content

```tsx
export default function Page() {
  return (
    <>
      <h1>Dashboard</h1>                                    {/* static */}
      <Suspense fallback={<Skeleton />}>
        <UserGreeting />                                     {/* dynamic, user-specific */}
      </Suspense>
    </>
  )
}

async function UserGreeting() {
  const session = await cookies()
  const name = session.get('name')?.value
  return <p>Welcome back, {name ?? 'Guest'}</p>
}
```

### Pattern 4: suppressHydrationWarning (last resort)

```tsx
<time suppressHydrationWarning>{new Date().toISOString()}</time>
```

**Only use when**: The mismatch is known, harmless, and unfixable (e.g., third-party ad scripts).

### Pattern 5: Theme (dark mode) — inline script, NOT useEffect

Deferring the theme to `useEffect` produces the classic light-mode flash. Set the class before hydration instead (this is what `next-themes` does):

```tsx
// app/layout.tsx
<html lang="en" suppressHydrationWarning>
  <head>
    <script
      dangerouslySetInnerHTML={{
        __html: `document.documentElement.classList.toggle('dark',
          localStorage.theme === 'dark' ||
          (!('theme' in localStorage) && matchMedia('(prefers-color-scheme: dark)').matches))`,
      }}
    />
  </head>
  <body>{children}</body>
</html>
```

`suppressHydrationWarning` on `<html>` covers only that element's attribute mismatch. In practice: just use `next-themes` — this is its whole job.

### Pattern 6: useSyncExternalStore for client-only values

Avoids Pattern 1's extra state + post-mount render by declaring what the server renders:

```tsx
function useMediaQuery(query: string) {
  return useSyncExternalStore(
    (notify) => {
      const mql = window.matchMedia(query)
      mql.addEventListener('change', notify)
      return () => mql.removeEventListener('change', notify)
    },
    () => window.matchMedia(query).matches,  // client snapshot
    () => false                              // server snapshot — what SSR renders
  )
}
```

React uses the server snapshot during SSR and hydration (so they match), then re-renders with the client snapshot — hydration-safe by construction.

---

## [HARD RULE] Common Misconceptions

### `typeof window !== 'undefined'` in render does NOT fix hydration

```tsx
// ❌ Still causes mismatch
function Clock() {
  if (typeof window !== 'undefined') {
    return <span>{new Date().toLocaleString()}</span>  // client
  }
  return <span>Loading...</span>  // server
  // During hydration, client runs BOTH paths and compares — MISMATCH
}

// ✅ useEffect defers to client only
function Clock() {
  const [time, setTime] = useState<string | null>(null)
  useEffect(() => setTime(new Date().toLocaleString()), [])
  return <span>{time ?? 'Loading...'}</span>
}
```

---

## Common Failure Modes

- Suppressing the warning without understanding the cause
- Using `typeof window` in render logic (causes mismatch, doesn't prevent it)
- Fixing theme flicker with `useEffect` → light-mode flash; use the inline-script pattern
- Assuming the error is in the highlighted component (may be a parent or layout)
- Third-party scripts injecting DOM nodes — React 19 skips these; on 18, test in incognito

## Safe Recommendation Template

1. React 19+: read the server/client diff in the error — it names the mismatched node
2. Identify what differs between server and client render
3. If element ID → `useId`. If other date/random → placeholder on server, real value after mount
4. If browser API → `useSyncExternalStore` with a server snapshot, or `useEffect` / `dynamic` in a client wrapper
5. If theme → pre-hydration inline script + `suppressHydrationWarning` (or `next-themes`)
6. If user-specific → `<Suspense>` boundary
7. If truly irrelevant (3rd-party injection) → `suppressHydrationWarning`
