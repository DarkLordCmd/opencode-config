# Tailwind CSS Patterns

Build a design system on top of Tailwind without losing the utility-first ergonomics.

## 1. Design Tokens via CSS Variables

The hard-coded `text-blue-500` everywhere is a smell. Define semantic tokens once, use them everywhere. Theming (dark mode, brand swap, multi-tenant) becomes a variable swap.

### Tailwind v4 (preferred, CSS-first config)

```css
/* app/globals.css */
@import "tailwindcss";

@theme {
  /* Brand */
  --color-brand-50:  oklch(0.97 0.02 250);
  --color-brand-500: oklch(0.65 0.18 250);
  --color-brand-900: oklch(0.25 0.10 250);

  /* Semantic surfaces */
  --color-bg:           var(--color-neutral-50);
  --color-bg-elevated:  var(--color-white);
  --color-fg:           var(--color-neutral-900);
  --color-fg-muted:     var(--color-neutral-500);
  --color-border:       var(--color-neutral-200);
  --color-ring:         var(--color-brand-500);
}

/* Dark theme — same names, different values */
@media (prefers-color-scheme: dark) {
  :root {
    --color-bg:           var(--color-neutral-950);
    --color-bg-elevated:  var(--color-neutral-900);
    --color-fg:           var(--color-neutral-50);
    --color-fg-muted:     var(--color-neutral-400);
    --color-border:       var(--color-neutral-800);
  }
}
```

Use them: `<div class="bg-bg-elevated text-fg border-border ring-ring">`.

### Tailwind v3 (legacy, JS config)

```ts
// tailwind.config.ts
import type { Config } from 'tailwindcss'
export default {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  darkMode: 'class',   // toggle dark mode by class on <html>
  theme: {
    extend: {
      colors: {
        bg: 'rgb(var(--color-bg) / <alpha-value>)',
        fg: 'rgb(var(--color-fg) / <alpha-value>)',
        // …
      },
      fontFamily: { sans: ['var(--font-inter)', 'sans-serif'] },
    },
  },
} satisfies Config
```

```css
/* globals.css */
@layer base {
  :root {
    --color-bg: 250 250 250;
    --color-fg: 23 23 23;
  }
  .dark {
    --color-bg: 10 10 10;
    --color-fg: 250 250 250;
  }
}
```

The triplet-with-space format lets `<alpha-value>` slot in for `bg-bg/50` style opacity.

## 2. Dark Mode Discipline

**Every color utility needs a `dark:` counterpart**, unless it's purposely the same in both modes (e.g., a brand accent). Half-dark UIs leak white flashes during transitions.

```tsx
// BAD
<div className="bg-white text-neutral-900 border border-neutral-200">…</div>

// GOOD
<div className="bg-white dark:bg-neutral-950 text-neutral-900 dark:text-neutral-50 border border-neutral-200 dark:border-neutral-800">…</div>

// BETTER — semantic tokens hide the branching
<div className="bg-bg-elevated text-fg border-border">…</div>
```

Choose `darkMode: 'class'` (toggleable) over `'media'` (forced by OS) unless the product has a hard policy.

### Avoid the dark-mode flash

For class-based dark mode, set the class **before** React hydrates — inline script in `<head>`:

```tsx
// app/layout.tsx (Next.js)
export default function RootLayout({ children }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `
              try {
                const t = localStorage.getItem('theme');
                const d = t === 'dark' || (!t && matchMedia('(prefers-color-scheme: dark)').matches);
                document.documentElement.classList.toggle('dark', d);
              } catch {}
            `,
          }}
        />
      </head>
      <body>{children}</body>
    </html>
  )
}
```

`suppressHydrationWarning` is required on `<html>` because the inline script mutates `class` before React's tree matches.

## 3. Class Composition

### Use `clsx` + `tailwind-merge` (or `cn`)

```ts
// lib/cn.ts
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

`clsx` handles conditional/falsy values; `tailwind-merge` resolves conflicts (`px-2` vs `px-4` → `px-4`).

```tsx
<button
  className={cn(
    'inline-flex items-center gap-2 rounded-md px-3 py-2 text-sm font-medium',
    'bg-brand-500 text-white hover:bg-brand-600',
    'disabled:opacity-50 disabled:cursor-not-allowed',
    isActive && 'ring-2 ring-brand-500',
    className,   // allow caller override at the end
  )}
/>
```

### Variants with `cva` (class-variance-authority)

For design-system components with a closed set of variants:

```ts
import { cva, type VariantProps } from 'class-variance-authority'

export const button = cva(
  'inline-flex items-center justify-center rounded-md font-medium transition focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none disabled:opacity-50',
  {
    variants: {
      intent: {
        primary:   'bg-brand-500 text-white hover:bg-brand-600',
        secondary: 'bg-bg-elevated text-fg border border-border hover:bg-bg',
        ghost:     'text-fg hover:bg-bg',
        danger:    'bg-red-600 text-white hover:bg-red-700',
      },
      size: {
        sm: 'h-8 px-3 text-xs',
        md: 'h-10 px-4 text-sm',
        lg: 'h-12 px-6 text-base',
      },
    },
    defaultVariants: { intent: 'primary', size: 'md' },
  }
)

export type ButtonProps = VariantProps<typeof button> &
  React.ButtonHTMLAttributes<HTMLButtonElement>

export function Button({ intent, size, className, ...props }: ButtonProps) {
  return <button className={cn(button({ intent, size }), className)} {...props} />
}
```

Typed variants, autocompleted in JSX, no string conditional spaghetti.

## 4. When to Extract a Component vs. Repeat Utilities

**Repeat utilities** when the visual recurs <3 times or differs slightly between uses. The whole point of Tailwind is to keep the styling local and the file count flat.

**Extract a component** when:
- The exact same class string appears 3+ times AND
- The behavior is coordinated (accessibility, state, interactivity) AND
- A future change to the styling should propagate everywhere

**Don't extract** `<Wrapper className="p-4 rounded-lg">` for a 2-line div used twice. That's a regression.

## 5. Responsive and State Variants

Mobile-first: unprefixed utilities are mobile; prefix at the breakpoint where it changes.

```tsx
<div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3 lg:gap-6">
```

State variants compose: `hover:`, `focus-visible:`, `active:`, `disabled:`, `group-hover:`, `peer-checked:`, `data-[state=open]:`, `aria-[expanded=true]:`.

```tsx
<button className="bg-brand-500 hover:bg-brand-600 focus-visible:ring-2 disabled:opacity-50 data-[loading=true]:cursor-wait" />
```

For `group-` and `peer-`, the parent/sibling needs the `group` or `peer` class:

```tsx
<div className="group">
  <span className="opacity-50 group-hover:opacity-100">Hover the parent</span>
</div>
```

## 6. Avoid Arbitrary Values When a Token Exists

```tsx
// BAD — magic numbers; doesn't theme
<div className="text-[#5e6c84] p-[18px]" />

// GOOD — semantic tokens; spacing scale
<div className="text-fg-muted p-4" />
```

Use arbitrary values only when the design genuinely doesn't fit the scale: `mt-[3px]` to compensate for an icon's optical baseline, `w-[37ch]` for prose width. Document the why in a comment.

## 7. Typography and Layout Primitives

### Type scale

Don't sprinkle `text-[15px]` everywhere. Use the scale (`text-sm`, `text-base`, `text-lg`, …) and define a hierarchy:

```tsx
function H1({ children }: { children: ReactNode }) {
  return <h1 className="text-3xl font-semibold tracking-tight text-fg">{children}</h1>
}
function H2({ children }: { children: ReactNode }) {
  return <h2 className="text-xl font-semibold tracking-tight text-fg">{children}</h2>
}
function Lead({ children }: { children: ReactNode }) {
  return <p className="text-base text-fg-muted">{children}</p>
}
```

For long-form content, `@tailwindcss/typography` and `prose` classes are appropriate.

### Container

```tsx
<main className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 py-8 sm:py-12">…</main>
```

Centralize this in a `<Container>` primitive if you use it more than ~3 times.

## 8. Accessibility Defaults

- **`focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:outline-none`** on every interactive element.
- **Don't `outline-none` without a replacement.** A focus ring is required.
- **`aria-` attributes** on tabs (`role="tablist"`, `role="tab"`, `aria-selected`, `aria-controls`, `role="tabpanel"`, `aria-labelledby`).
- **`<button type="button">`** explicitly inside forms unless it's the submit.
- **`text-sm` minimum for body text on light backgrounds.** Don't ship `text-xs` for anything informational.
- **Color contrast:** verify with the browser devtools; semantic tokens make audits easier.

## 9. Performance

- **`content-visibility: auto`** on long off-screen lists (`class="[content-visibility:auto]"`).
- **JIT/v4 only purges what you use** — but dynamic class names won't be detected. Don't construct utilities like `` `bg-${color}-500` ``; use a lookup `{ red: 'bg-red-500', blue: 'bg-blue-500' }[color]`.
- **`@apply` sparingly** — usually it's the wrong direction. Prefer a `cva` variant or a component.

## 10. Common Mistakes

| Mistake | Fix |
|---|---|
| `<div class="bg-white">…</div>` no dark | `bg-white dark:bg-neutral-950` or `bg-bg-elevated` |
| Building class strings: `` `text-${color}-500` `` | Static lookup table or `cva` |
| `className={isActive ? "..." : "..."}` repeated | `cn(base, isActive && active)` or `cva` |
| Heavy use of `text-[14px]`, `p-[7px]` | Stick to the scale; tokens for exceptions |
| Forgetting `focus-visible:ring-*` | Add it to every interactive primitive once |
| `<a className="…">` for buttons | Use `<button>` (or `<Link>` for nav). `<a>` without `href` isn't accessible. |
| `dark:` only on text, not background | Pair them. White-on-white in dark mode is bad. |
| One-off `@apply` instead of `cva` | Convert when you find yourself repeating the pattern. |

## Self-Audit Checklist

- [ ] Semantic tokens (`bg-bg`, `text-fg`, `border-border`) for surfaces, not raw palette names
- [ ] Every color utility has a `dark:` counterpart or uses a theme variable
- [ ] Class composition uses `cn(clsx + twMerge)`, not string concatenation
- [ ] Closed variant sets use `cva` for type safety
- [ ] Focus ring on every interactive element
- [ ] No constructed utility names (no template literals into class strings)
- [ ] Arbitrary values (`[…]`) only when the scale truly doesn't fit, with a reason
- [ ] Class-based dark mode has an inline pre-hydration script
