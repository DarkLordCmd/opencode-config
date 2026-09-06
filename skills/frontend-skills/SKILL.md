---
name: frontend-skills
description: Use when writing, reviewing, or refactoring React 19, Next.js 14+ / 16 App Router, or Tailwind CSS code. Triggers on tasks involving Server/Client Components, data fetching, cache directives, route handlers, image/font optimization, component API design, or Tailwind class composition.
---

# React + Next.js + Tailwind

Build production frontends that are fast by default and easy to change.

## Core Mental Model

In Next.js App Router, **every file is a Server Component until you opt out**. Code only runs on the client when it has to (interactivity, browser APIs, hooks). Data is fetched where it's used (server-side, no API hop). Static, cached, and dynamic content **coexist on the same page**.

Before you write a component, answer four questions:

```dot
digraph where_runs {
    rankdir=LR;
    "Needs useState/useEffect/event handlers/browser API?" [shape=diamond];
    "Mutation (form submit, write)?" [shape=diamond];
    "External clients/webhooks consume it?" [shape=diamond];
    "Server Component (default)" [shape=box];
    "Client Component ('use client')" [shape=box];
    "Server Action ('use server')" [shape=box];
    "Route Handler (route.ts)" [shape=box];

    "Needs useState/useEffect/event handlers/browser API?" -> "Client Component ('use client')" [label="yes"];
    "Needs useState/useEffect/event handlers/browser API?" -> "Mutation (form submit, write)?" [label="no"];
    "Mutation (form submit, write)?" -> "Server Action ('use server')" [label="yes"];
    "Mutation (form submit, write)?" -> "External clients/webhooks consume it?" [label="no"];
    "External clients/webhooks consume it?" -> "Route Handler (route.ts)" [label="yes"];
    "External clients/webhooks consume it?" -> "Server Component (default)" [label="no"];
}
```

## Top-Impact Rules (CRITICAL)

These are the rules whose violation costs the most. Treat them as defaults; deviate only with a stated reason.

| # | Rule | Why it matters |
|---|------|----------------|
| 1 | **No `export const dynamic = 'force-dynamic'`** on Next.js 16+. Use `'use cache'` for cacheable async work, `<Suspense>` for live data. (Import `cacheLife`/`cacheTag` from `next/cache` — alias from `unstable_*` if your version still ships them under that prefix.) | Cache Components let static/cached/dynamic coexist in one route. `force-dynamic` blocks every optimization. |
| 2 | **Parallelize independent awaits with `Promise.all`** — never serial `await` for unrelated work. | 2–10× latency reduction on multi-fetch routes. |
| 3 | **Configure `optimizePackageImports`** in `next.config.ts` for any icon/UI library you import (`lucide-react`, `@mui/*`, `@radix-ui/*`, `date-fns`, etc.). | Barrel imports load 1,500–10,000 modules; 200–800 ms cold start cost. |
| 4 | **Use `next/link` for internal navigation, `next/image` for every image, `next/font` for every font.** Never raw `<a href="/...">`, `<img>`, or `<link rel="stylesheet">` font URLs. | Lose prefetching, layout shift, font swapping. |
| 5 | **Serialize props that cross the Server→Client boundary.** Dates become ISO strings, Maps/Sets become arrays/objects, no functions (except Server Actions). | Class methods are stripped, Dates silently coerce to strings, then crash on `.getFullYear()`. |
| 6 | **No `async` Client Components.** Fetch data in a Server parent and pass plain props down. | Async client components throw at runtime. |
| 7 | **Wrap dynamic streaming work in `<Suspense>` with a real skeleton fallback.** Add `loading.tsx` at the segment level for the route shell. | Streaming requires Suspense; the skeleton is the UX. |
| 8 | **Prefer composition over boolean props.** `<Modal isHeader isFooter isDismissible>` → `<Modal.Frame><Modal.Header/>…`, or distinct `<ChannelComposer/>` / `<ThreadComposer/>` variants. | Booleans multiply state combinatorially; compound components stay linear. |
| 9 | **Don't `try/catch` `redirect()`, `notFound()`, `forbidden()`, or `unauthorized()`.** They throw on purpose — let them through, or `unstable_rethrow(error)` in a catch. | Catching them silently breaks navigation. |
| 10 | **Tailwind: pair every color with its `dark:` variant.** Use semantic tokens via CSS variables for theming. Conditional classes via `clsx`/`cn`, not string templates. | Half-dark UIs leak white flashes. Strings with conditionals are unreadable. |

## What Goes Where

| You want to… | Use |
|---|---|
| Read data for a page | **Server Component** — `await db.…` directly, no API |
| Cache an expensive read for the route | `'use cache'` + `cacheLife()` + `cacheTag()` |
| Handle a form submit / write | **Server Action** (`'use server'` file, pass to `<form action={…}>`) |
| Build a REST API for mobile / webhooks | **Route Handler** (`app/api/.../route.ts`) |
| Client-side fetch with deduplication | SWR (or TanStack Query) inside a Client Component |
| Run code once per request, deduped | `react.cache()` |
| Run code once per app load | Module-level `let cached; export function get() { return cached ??= … }` |
| Add interactivity to a single leaf | Mark **only that leaf** `'use client'` — keep the page server |

## Deep References

Skim these when working in the relevant area. Each is dense reference material, not narrative.

- **[references/nextjs.md](references/nextjs.md)** — Next.js 16 Cache Components, RSC boundaries, async params/cookies, file conventions, data patterns, error handling, image/font, scripts, parallel routes.
- **[references/react-performance.md](references/react-performance.md)** — Eliminating waterfalls, bundle-size traps, server-side caching (`react.cache`, LRU, hoist static I/O), re-render optimization, advanced patterns.
- **[references/composition.md](references/composition.md)** — Compound components, lift-state-into-provider, explicit variants, children over render props, React 19's `use()` replacing `forwardRef`.
- **[references/tailwind.md](references/tailwind.md)** — Design tokens via CSS variables, dark mode discipline, `clsx`/`cn`/`tailwind-merge`, when to extract components vs. when to repeat utilities, responsive/state variants.
- **[references/design-principles.md](references/design-principles.md)** — Refactoring UI school: hierarchy, whitespace, color, depth, polish. Read when the UI works but feels generic or undesigned.
- **[references/ui-patterns.md](references/ui-patterns.md)** — Catalog of standard UI patterns (shells, navigation, forms, tables, modals, toasts, etc.) with composition + accessibility shape for each.
- **[references/common-mistakes.md](references/common-mistakes.md)** — Before/after for the failures that show up most often, with diagnosis.

## Common Mistakes — Quick Hits

| Mistake | Fix |
|---|---|
| `export const dynamic = 'force-dynamic'` everywhere | Remove. Use `'use cache'` for cacheable, `<Suspense>` for live, on Next.js 16+. |
| `import { Icon } from 'lucide-react'` with no `optimizePackageImports` | Add it to `next.config.ts`. Or import from the package's deep path. |
| `<a href="/posts/[id]">` for internal routes | `<Link href={`/posts/${id}`}>` — restores prefetch + client nav. |
| `<img src="...">` | `<Image src=… alt=… width height />` or `fill` + `sizes`. |
| `'use client'` at the top of the page | Push it down to the smallest interactive leaf. Keep parents server. |
| `new Date(...)` passed as a prop to a Client Component | `.toISOString()` server-side, re-parse on the client. |
| 5 booleans on one component | Split into compound (`X.Root`, `X.Item`) or distinct variants. |
| Inline `className={isActive ? "..." : "..."}` strings repeated 6 times | Extract a variant helper (`cva`) or a component. |
| `notFound()` mentioned in a comment but not called | Call it. It throws and renders the closest `not-found.tsx`. |
| One huge `Promise.all` blocking the entire page | Wrap slow parts in `<Suspense>` so the rest streams. |

## Red Flags — Stop and Reconsider

- **You're about to add the 3rd boolean prop.** → Switch to composition.
- **You wrote `await` twice in a row on unrelated values.** → `Promise.all`.
- **You typed `'use client'` to fix an error you don't understand.** → Find the real cause (often: trying to `await` in a client component, or pass a function from server).
- **You're caching everything `force-dynamic` or nothing at all.** → Pick what's cacheable per-component with `'use cache'`.
- **You're writing your own image lazy-loader / route prefetch / font CSS.** → `next/image` / `next/link` / `next/font` already do it.
- **A class instance, `Date`, `Map`, or function is on the props edge of a Client Component.** → Serialize at the boundary.

## When NOT to Apply

- Pure SPA (Vite + React, no SSR) — RSC and `'use cache'` rules don't apply; React performance rules and Tailwind rules still do.
- Pages router (legacy Next.js) — file conventions differ; data-patterns and component patterns still apply.
- Outside React — only the broad principles (parallelize async, design tokens) carry over.
