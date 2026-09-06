# UI Patterns Reference

A taxonomy of UI patterns an agent should recognize and reach for, organized like a Tailwind UI catalog. For each pattern: when to use it, the structural shape, and the accessibility requirements that matter most.

Pair this with `composition.md` (how to architect the component) and `tailwind.md` (how to style it).

## Categories at a glance

- **Application shells** — page chrome (nav + sidebar + content)
- **Headings** — page/section titles with metadata and actions
- **Layout** — containers, panels, multi-column structures
- **Navigation** — top nav, sidebar nav, breadcrumbs, pagination, tabs
- **Forms** — inputs, selects, comboboxes, fieldsets, validation
- **Data display** — tables, description lists, stat cards, calendars
- **Lists** — feeds, stacked lists, grid lists
- **Feedback** — alerts, banners, empty states, progress, skeletons
- **Overlays** — modals, drawers, popovers, command palette, tooltips, toasts
- **Elements** — buttons, badges, avatars, button groups, dropdowns

---

## Application shells

The chrome around your routes. Three common shapes:

| Shell | When to use |
|---|---|
| **Top nav only** | Marketing sites, simple apps with 3–5 destinations |
| **Side nav (constant)** | Dashboards, IDE-like tools, anything with 6+ destinations |
| **Top nav + collapsible sidebar** | SaaS with primary nav + contextual secondary nav |

Structure (constant sidebar):

```tsx
<div className="flex h-dvh">
  <aside className="w-64 shrink-0 border-r border-border bg-bg-elevated">
    {/* logo, nav, account */}
  </aside>
  <div className="flex flex-1 flex-col overflow-hidden">
    <header className="h-14 border-b border-border bg-bg-elevated">
      {/* breadcrumb, search, user menu */}
    </header>
    <main className="flex-1 overflow-auto">{children}</main>
  </div>
</div>
```

Use `h-dvh` (dynamic viewport height), not `h-screen` — fixes iOS Safari address-bar overlap.

A11y: landmark roles (`<header>`, `<nav>`, `<main>`, `<aside>` carry them implicitly); each landmark needs an `aria-label` if there are multiples (e.g., primary nav vs. secondary).

## Headings

Page heading anatomy:

```tsx
<header className="flex flex-wrap items-end justify-between gap-4 border-b border-border pb-5">
  <div className="min-w-0">
    {/* breadcrumbs */}
    <nav aria-label="Breadcrumb" className="text-sm text-fg-muted">
      <ol className="flex items-center gap-2">…</ol>
    </nav>
    <h1 className="mt-2 truncate text-2xl font-semibold tracking-tight">{title}</h1>
    {subtitle && <p className="mt-1 text-sm text-fg-muted">{subtitle}</p>}
  </div>
  <div className="flex items-center gap-2">
    {/* secondary actions */}
    {/* primary action */}
  </div>
</header>
```

Primary action goes rightmost. Subtitle is optional and short. Truncate the title on overflow; don't wrap.

## Layout

- **Container:** `mx-auto max-w-7xl px-4 sm:px-6 lg:px-8`. One value per project; centralize in a `<Container>` primitive.
- **Page section:** vertical rhythm via `space-y-{n}` on a section, not `mt-{n}` on individual children.
- **Two-column with sidebar:** `grid grid-cols-1 lg:grid-cols-[1fr_320px] lg:gap-8` — content fluid, sidebar fixed-width.
- **Card:** `rounded-2xl border border-border bg-bg-elevated p-6 shadow-sm`. Replace the border with shadow on busier pages.

## Navigation

### Tabs

Compound component (see `composition.md`):

```tsx
<TabBar.Root defaultActive="overview" ariaLabel="Section">
  <TabBar.Bar>
    <TabBar.Tab id="overview">Overview</TabBar.Tab>
    <TabBar.Tab id="activity" badge="3">Activity</TabBar.Tab>
    <TabBar.Tab id="settings">Settings</TabBar.Tab>
  </TabBar.Bar>
  <TabBar.Panel id="overview">…</TabBar.Panel>
</TabBar.Root>
```

A11y: `role="tablist"` on the bar, `role="tab"` + `aria-selected` + `aria-controls` on each tab, `role="tabpanel"` + `aria-labelledby` on each panel. Arrow-key navigation between tabs is expected.

### Sidebar nav (sectioned)

```tsx
<nav className="flex flex-col gap-6" aria-label="Primary">
  <ul className="space-y-1">{primaryItems.map(NavItem)}</ul>
  <div>
    <div className="px-2 pb-1 text-xs font-semibold uppercase tracking-wide text-fg-muted">Workspaces</div>
    <ul className="space-y-1">{workspaceItems.map(NavItem)}</ul>
  </div>
</nav>
```

Active state via `data-active` attribute + `data-[active=true]:bg-…` rather than conditional class strings.

### Breadcrumbs

`<nav aria-label="Breadcrumb">` containing `<ol>`. Last item is `aria-current="page"` and not a link.

### Pagination

Two flavors:

- **Numbered** — for paginated tables/lists. Always include first/last/prev/next + a few surrounding pages with ellipsis (`1 … 14 15 16 … 87`).
- **Prev/Next only** — for content (blog posts, docs). No counts.

Always announce changes with `aria-live="polite"` on the count, or move focus to the top of the new page.

## Forms

Input anatomy:

```tsx
<div>
  <label htmlFor="email" className="block text-sm font-medium">Email</label>
  <input
    id="email"
    type="email"
    aria-describedby="email-help"
    aria-invalid={!!error}
    className="mt-1 block w-full rounded-md border border-border bg-bg-elevated px-3 py-2 text-sm shadow-sm focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none aria-[invalid=true]:border-red-500"
  />
  {error
    ? <p id="email-help" className="mt-1 text-xs text-red-600">{error}</p>
    : <p id="email-help" className="mt-1 text-xs text-fg-muted">We'll never share it.</p>}
</div>
```

Rules:
- `<label htmlFor>` for every input, every time. No exceptions (placeholders are not labels).
- `aria-describedby` for help/error text.
- `aria-invalid="true"` when invalid; style with `aria-[invalid=true]:`.
- Group related inputs in a `<fieldset>` with `<legend>`.
- For checkboxes/radios: native first; reach for `@radix-ui/react-checkbox` only when the design demands custom controls.

### Form layout

Single-column forms convert better than multi-column. Reserve two-column for clearly paired fields (first + last name, city + zip).

### Validation timing

- **On submit** — default. Don't bother users while they're typing.
- **On blur** — for fields with formats (email, phone). Validate when they leave the field, never per keystroke.
- **On change** — only after the first failed submit, for re-checking that the user has now fixed the issue.

### Submit buttons

Disabled state while pending, with a spinner. The label changes: "Save changes" → "Saving…". Both `aria-busy="true"` and `disabled`.

## Data display

### Tables

```tsx
<div className="overflow-x-auto">
  <table className="min-w-full divide-y divide-border">
    <thead>
      <tr>
        <th scope="col" className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-fg-muted">Name</th>
        …
      </tr>
    </thead>
    <tbody className="divide-y divide-border">
      <tr><td className="px-3 py-2">…</td></tr>
    </tbody>
  </table>
</div>
```

Rules:
- `<th scope="col">` on every header cell.
- Right-align numeric columns. `text-right tabular-nums`.
- Sticky header on long tables: `sticky top-0 bg-bg-elevated`.
- Don't use tables for layout. Don't use divs for tabular data.

### Description lists

For key/value pairs that don't repeat (single-entity detail views):

```tsx
<dl className="divide-y divide-border">
  <div className="grid grid-cols-3 gap-4 py-3">
    <dt className="text-sm font-medium text-fg-muted">Owner</dt>
    <dd className="col-span-2 text-sm">Ada Lovelace</dd>
  </div>
  …
</dl>
```

### Stat cards

```tsx
<dl className="grid grid-cols-1 gap-4 sm:grid-cols-3">
  <div className="rounded-2xl border border-border bg-bg-elevated p-5">
    <dt className="text-sm text-fg-muted">Active users</dt>
    <dd className="mt-1 flex items-baseline gap-2">
      <span className="text-3xl font-semibold tabular-nums">12,840</span>
      <span className="text-sm text-emerald-600">+4.3%</span>
    </dd>
  </div>
</dl>
```

`tabular-nums` so numbers align across stats with different digit counts.

## Lists

### Stacked (feed)

```tsx
<ul className="divide-y divide-border rounded-2xl border border-border bg-bg-elevated">
  {items.map(item => (
    <li key={item.id} className="flex items-start gap-3 p-4">
      …
    </li>
  ))}
</ul>
```

### Grid

```tsx
<ul className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
  {items.map(item => <li key={item.id}>…</li>)}
</ul>
```

Use a card per item; don't add per-item borders if the cards already have them.

## Feedback

### Alerts

Four severities (info / success / warning / error), all with the same anatomy:

```tsx
<div role="alert" className="flex items-start gap-3 rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-900 dark:border-red-900/40 dark:bg-red-950/30 dark:text-red-200">
  <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" aria-hidden />
  <div className="min-w-0 flex-1">
    <p className="font-semibold">{title}</p>
    <p className="mt-1">{description}</p>
  </div>
  <button aria-label="Dismiss" className="…"><X className="h-4 w-4" /></button>
</div>
```

`role="alert"` for errors that appear post-action; omit for static inline messages.

### Empty states

The most under-designed pattern. Anatomy: illustration/icon + 1-line headline + 1-line description + primary CTA.

```tsx
<div className="rounded-2xl border-2 border-dashed border-border p-12 text-center">
  <Inbox className="mx-auto h-10 w-10 text-fg-muted" aria-hidden />
  <h3 className="mt-3 text-sm font-semibold">No invoices yet</h3>
  <p className="mt-1 text-sm text-fg-muted">Get started by creating your first invoice.</p>
  <button className="mt-4 …">New invoice</button>
</div>
```

### Skeletons

Match the *shape* of the loaded content, not generic rectangles. A list with avatars + 2 lines of text needs a skeleton with circle + 2 bars.

```tsx
<div className="space-y-3">
  {Array.from({ length: 3 }).map((_, i) => (
    <div key={i} className="flex items-center gap-3">
      <div className="h-10 w-10 animate-pulse rounded-full bg-bg-muted" />
      <div className="flex-1 space-y-2">
        <div className="h-4 w-3/4 animate-pulse rounded bg-bg-muted" />
        <div className="h-3 w-1/2 animate-pulse rounded bg-bg-muted" />
      </div>
    </div>
  ))}
</div>
```

### Progress

- **Determinate:** show a numeric value too (`75%`). Don't make users guess.
- **Indeterminate:** spinner or marquee bar. Use only when the duration is unknown.

## Overlays

### Modal / Dialog

Use a headless library (`@radix-ui/react-dialog` or `@headlessui/react`). Don't build from scratch — the focus management, scroll lock, and Escape handling are non-trivial.

```tsx
<Dialog.Root open={open} onOpenChange={setOpen}>
  <Dialog.Portal>
    <Dialog.Overlay className="fixed inset-0 bg-black/50" />
    <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border bg-bg-elevated p-6 shadow-xl focus:outline-none">
      <Dialog.Title className="text-lg font-semibold">Title</Dialog.Title>
      <Dialog.Description className="mt-1 text-sm text-fg-muted">Description</Dialog.Description>
      {/* content */}
      <div className="mt-6 flex justify-end gap-2">
        <Dialog.Close asChild><button className="…">Cancel</button></Dialog.Close>
        <button className="…">Confirm</button>
      </div>
    </Dialog.Content>
  </Dialog.Portal>
</Dialog.Root>
```

A11y musts: focus traps inside the dialog, restored on close. `aria-labelledby` on the content matching the title's id. Escape closes.

### Drawer / Sheet

Same accessibility shape as Dialog; positioned on an edge of the viewport. Use for: filters, secondary forms, navigation on mobile.

### Popover

For non-modal floating content (date pickers, color pickers, settings menus). Use `@radix-ui/react-popover` for positioning + collision handling.

### Tooltip

For optional supplementary info only. Never for critical information (touch devices have no hover). Delay open by 300–500 ms; close instantly. Use `@radix-ui/react-tooltip`.

### Command palette

Modal with a single input + result list. `Cmd+K` or `Ctrl+K` to open. Use `cmdk` library — building from scratch is a multi-day project.

### Toasts

Non-blocking confirmations of background actions. Library: `sonner` (simplest) or `react-hot-toast`.

Rules:
- Auto-dismiss success after 3–4 s; errors persist until dismissed.
- One position per app (usually `bottom-right`); never multiple.
- `role="status"` for non-urgent, `role="alert"` for errors.

## Elements

### Button

```tsx
import { cva, type VariantProps } from 'class-variance-authority'

const button = cva(
  'inline-flex items-center justify-center gap-2 rounded-md font-medium transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-bg disabled:opacity-50 disabled:cursor-not-allowed',
  {
    variants: {
      intent: {
        primary:   'bg-brand-600 text-white hover:bg-brand-700',
        secondary: 'border border-border bg-bg-elevated text-fg hover:bg-bg-muted',
        ghost:     'text-fg hover:bg-bg-muted',
        danger:    'bg-red-600 text-white hover:bg-red-700',
        link:      'text-brand-600 underline-offset-4 hover:underline',
      },
      size: {
        sm: 'h-8 px-3 text-xs',
        md: 'h-9 px-4 text-sm',
        lg: 'h-11 px-6 text-base',
        icon: 'h-9 w-9',
      },
    },
    defaultVariants: { intent: 'primary', size: 'md' },
  }
)
```

Always include `focus-visible:ring`. Always include a `disabled` style. Loading state shows a spinner inside the button.

### Badge

For status labels and counts. `inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium`. Color signals state (green = success, amber = warning, red = error, blue = info, gray = neutral). Don't overload — five colors max.

### Avatar

```tsx
<span className="inline-flex h-10 w-10 items-center justify-center overflow-hidden rounded-full bg-bg-muted text-sm font-medium">
  {imageUrl
    ? <Image src={imageUrl} alt={name} fill sizes="40px" className="object-cover" />
    : initials(name)}
</span>
```

Always fallback to initials when the image fails. `alt` is the person's name, not "avatar".

### Dropdown menu

`@radix-ui/react-dropdown-menu`. Don't build from scratch — keyboard navigation, focus trapping, and proper roles are easy to get wrong.

### Button groups (segmented control)

```tsx
<div role="group" className="inline-flex rounded-md border border-border bg-bg-elevated p-0.5">
  {options.map(opt => (
    <button
      key={opt}
      type="button"
      aria-pressed={value === opt}
      onClick={() => onChange(opt)}
      className="rounded px-3 py-1.5 text-sm aria-[pressed=true]:bg-bg-muted aria-[pressed=true]:text-fg text-fg-muted"
    >
      {opt}
    </button>
  ))}
</div>
```

For radio-group semantics, use `role="radiogroup"` instead and `aria-checked`.

## When to reach for a headless library

Build from scratch: button, badge, card, alert, simple list, stat card, breadcrumb, basic form input.

Use a headless library (`@radix-ui/*`, `@headlessui/react`, `cmdk`, `sonner`, `vaul`): dialog, popover, dropdown menu, tooltip, combobox, date picker, command palette, toast, drawer, accordion, tabs (when you need full keyboard nav), select.

Rule: anything with non-trivial focus management or keyboard navigation, use a library. Anything purely visual, build it.

## Self-Audit

- [ ] Every input has a `<label htmlFor>` and `aria-describedby` for help/error
- [ ] Every interactive element has a visible `focus-visible` style
- [ ] Modals/dropdowns/tooltips come from headless libraries, not handwritten
- [ ] Tables use `<th scope>`, numeric columns are `text-right tabular-nums`
- [ ] Empty states have illustration + headline + description + CTA, not just "No data"
- [ ] Skeletons match the loaded content's shape, not generic rectangles
- [ ] Alerts use `role="alert"` only when they appear after an action
- [ ] Avatars fall back to initials; `alt` is the person's name
- [ ] Toasts have a single position; success auto-dismisses, error persists
