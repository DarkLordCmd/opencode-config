---
name: frontend-web
description: TanStack Router + React frontend patterns, ConnectRPC gRPC-Web client, Zustand stores, Tailwind v4, i18n, and AppearancePanel theming for the Anachak platform.
---

# Frontend Web Skill

The web frontend at `web/` — a **React 19** SPA using **TanStack Router**, **Zustand**, **ConnectRPC**, and **Tailwind CSS v4**.

## Tech Stack

| Layer | Technology | Version |
|---|---|---|
| Framework | React | 19 |
| Router | TanStack Router (file-based) | 1.167+ |
| State | Zustand | 5 |
| Styling | Tailwind CSS v4 + CSS custom properties | 4.2 |
| gRPC Client | ConnectRPC (gRPC-Web) | 2.1 |
| Proto Codegen | `@bufbuild/protoc-gen-es` | 2.11 |
| Icons | HugeIcons React | 1.1 |
| UI Primitives | Radix UI + shadcn/ui v4 | Latest |
| Animations | Framer Motion | 12 |
| Font | Geist Variable + Khmer fonts | Google Fonts |
| Toast | goey-toast | 0.4 |
| Build | Vite 7 | 7.3 |
| Test | Vitest + Testing Library | 3.2 |
| Package Manager | Bun | Latest |

## Quick Reference

| Topic | File |
|---|---|
| Folder structure | [folder-structure.md](./folder-structure.md) |
| Routing & layouts | [routing.md](./routing.md) |
| State management | [state-management.md](./state-management.md) |
| gRPC client | [grpc-client.md](./grpc-client.md) |
| Theming system | [theming.md](./theming.md) |
| i18n | [i18n.md](./i18n.md) |
| Component patterns | [components.md](./components.md) |
| SVG icon system | [svg-icons.md](./svg-icons.md) |
| Color system | [colors.md](./colors.md) |

## Entrypoints

| File | Purpose |
|---|---|
| `main.tsx` | ReactDOM render with `RouterProvider` |
| `router.tsx` | `createRouter()` with `routeTree`, scroll restoration, prefetch |
| `routes/__root.tsx` | Root layout: `<Outlet />` + `<GooeyToaster />` |
| `routes/_auth.tsx` | Auth layout: dark bg, noise grain, centered card |
| `routes/_app.tsx` | Dashboard layout: sidebar + header + themed content card |
| `styles.css` | Global Tailwind + CSS custom properties + keyframes |

## Ports

| Port | Purpose |
|---|---|
| `3000` | Vite dev server (`bun run dev`) |
| `50050` | Backend gRPC (proxied via ConnectRPC gRPC-Web) |

## Key Patterns

1. **File-based routing** — TanStack Router auto-generates `routeTree.gen.ts` from `routes/` directory
2. **Layout groups** — `_auth/` (login/register) and `_app/` (dashboard) with shared layouts
3. **Zustand stores** — 5 stores: `useAuth`, `useAppearanceStore`, `useCompanyStore`, `useSidebarStore`, `useTabStore`
4. **ConnectRPC gRPC-Web** — Type-safe clients generated from proto, one per service (12 clients)
5. **CSS custom properties** — `AppearanceStore` writes 50+ CSS vars to `:root` via `applyToDOM()`
6. **OKLCH color system** — 12 color presets with 11-step scales in OKLCH color space
7. **View Transitions API** — Circular-reveal theme toggle (light ↔ dark)
8. **Khmer/English i18n** — Zustand-based with dotted key paths and interpolation
9. **56 shadcn/ui components** — Radix-based primitives in `components/ui/`
10. **Auth flow** — JWT token rotation with auto-refresh timer, Google One Tap, 2FA support
