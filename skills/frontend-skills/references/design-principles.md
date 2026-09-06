# Design Principles for Agent-Generated UIs

Universal design principles distilled into agent-applicable rules. When a UI works but feels generic, undesigned, or "AI-shaped," the failure is usually concentrated in **hierarchy**, **whitespace discipline**, **color systems**, or **depth**. Run this file as a checklist before declaring a UI done.

Pair with `tailwind.md` (how to express these in Tailwind) and `ui-patterns.md` (concrete component shapes).

## How to read this file

Sections are organized by the order in which an agent makes decisions while generating a UI: pick personality → establish systems → place hierarchy → tune whitespace → add color → add depth → add polish. Don't read end-to-end; jump to the section that matches what you're doing right now.

---

## 1. Pick a personality before you place anything

A UI gets its character from four levers that must agree:

- **Typeface.** Serifs read editorial. Geometric sans reads modern/tech. Rounded sans reads friendly. Mono reads developer-tool.
- **Saturation.** Bright = playful/consumer. Muted = professional/serious. Monochrome with one accent = editorial.
- **Corner radius.** `rounded-none` reads utilitarian. `rounded-md` reads neutral. `rounded-2xl` and up reads friendly. `rounded-full` on buttons reads marketing.
- **Voice.** "Submit" vs. "Save changes" vs. "Looks good, save!" — same action, three personalities.

The #1 marker of an undesigned UI is these levers disagreeing: formal copy + cartoon illustrations + tight tracking + huge radii. Pick a personality, then every later decision becomes a yes/no against it.

## 2. Greyscale and structure first; color and detail last

- First pass should be black/white/grey, low-fi, structural. If the UI doesn't read in greyscale, color won't save it.
- Don't pre-design a hundred screens before shipping any. Most "perfect upfront" designs require rework once the data fights back.
- Design every state, not just the happy path: empty, loading, error, one-result, two-results, two-hundred-results, names that are 47 characters long.

## 3. Establish systems, then place tokens

Before placing a single value, define the systems you'll draw from:

- A **spacing scale** — `4, 8, 12, 16, 24, 32, 48, 64, 96`. Note the larger steps grow geometrically (~1.5× per step), not linearly. Large gaps need to be visibly larger than medium gaps. Tailwind's default scale already handles this; respect it.
- A **type scale** of 4–6 sizes you'll actually use, plus 2–3 weights. The full `text-xs` → `text-9xl` range is too many; pick what you need.
- A **color system** with 8–10 greys, one or two primaries (5–9 shades each), and 3–4 status accents (success, warning, danger, info — 3–5 shades each). Naive "blue + red" palettes always look unfinished.
- A **shadow ladder** — 3–5 elevation steps used consistently (input/card/hover/dropdown/modal).
- A **radius set** — usually 3 values (small/medium/large), maybe a `rounded-full` for circular elements.

If a value appears as an arbitrary number twice, it should be in the system. Components reach for token names (`bg-bg-elevated`, `text-fg-muted`, `shadow-md`), not raw values.

## 4. Place hierarchy before you style anything

This is where agent-generated UIs fail most often. Every screen has a primary action, secondary actions, and tertiary actions. They must look like it.

### Rank the actions

Every action on a screen sits in a pyramid:

- **Primary action** — solid, high-contrast background. One per screen.
- **Secondary action** — outlined, ghost, or muted fill.
- **Tertiary action** — styled like a link, no chrome.

Semantics don't decide the ranking — purpose does. A "Cancel" button might be primary on a confirmation screen (the safer action) or tertiary on a settings page (the trivial action). Destructive doesn't mean loud; it usually means outlined-red, not filled-red.

### Use levers in combination

Three levers create hierarchy: **size**, **weight** (bold/regular), and **contrast** (color distance from background). Pulling any one too hard reads heavy-handed:

- Going from `text-base` to `text-3xl` *and* `font-bold` is shouting twice. Pick one.
- Hierarchy from contrast (very dark text on white) is subtle and elegant.
- Hierarchy from size alone needs more space around the larger element.

### The grey-text-on-color trap

Grey text on white reads as "less important." Grey text on a colored background reads as washed-out and broken. The visual effect we like is *reduced contrast*, not *grey*.

For text on a colored background, hand-pick a color in the same family as the background, then shift saturation and lightness toward white until the contrast feels right. Don't reach for opacity — `text-white/60` looks faded and breaks over textured backgrounds.

### Quiet the surroundings, don't shout the target

When the main element doesn't stand out, the answer is usually to soften the things around it, not to make it louder. An active nav item that won't pop? Make the inactive items softer. A primary button that vanishes? Tone down the secondary buttons.

This applies at every scale: if a sidebar competes with main content, removing the sidebar's background may be the fix, not adding more chrome to main.

### Compensate weight with contrast (and vice versa)

A solid icon next to text steals attention because it covers more area. Compensate by giving the icon a softer color — same hierarchy, no shouting. Conversely, a 1px border that's too quiet shouldn't get darker; it should get thicker. Weight and contrast are interchangeable counterweights.

### Visual hierarchy ≠ document hierarchy

`<h1>` is for SEO and screen readers. The visually largest element on the page can be styled however you want. Don't fight the heading structure to make something feel important — set the structure correctly, then style independently.

### Combine labels and values; don't list them

When showing data, avoid `Label: value` lists where every label/value pair gets equal emphasis. Instead, make the value loud and the label/unit soft:

- ❌ `Price: $1,200 · Plan: Pro · Renews: May 31`
- ✅ `$1,200<small> / month</small>` followed by `Pro plan · Renews May 31`

The label exists only when the value would be ambiguous without it. Often you don't need the label at all.

## 5. Whitespace: start with too much, then remove

- **Add more whitespace than feels right**, then trim. Tight layouts read undesigned.
- When something feels off, the answer is usually *more space around it*, not less. Add, then remove from elsewhere if needed.
- Dense layouts have their place — trading platforms, IDEs, admin dashboards — but they use the same systemic spacing at a smaller step, never random values.
- Distance encodes grouping. Tight pairs belong together; spacious pairs are unrelated. Pad sections, not individual elements within them.
- Avoid ambiguous spacing: if two elements are equidistant from a divider, neither clearly "belongs to" it. Pull each element closer to its real owner.

## 6. Layout: constrain the canvas

- A 75ch-wide paragraph on a 24" monitor is unreadable. Centering with a max-width is the default, not the exception.
- Card-shaped containers, narrower content columns, asymmetric grids — these add structure and direct attention. Edge-to-edge is harder, not easier.
- Pick column counts per breakpoint and stick to them (`grid-cols-1 sm:grid-cols-2 lg:grid-cols-3`). Random `w-3/7` widths look ad-hoc.
- Grid is for 2D layouts (galleries, dashboards, tables). Flex is better for "three things in a row." Reaching for grid when flex would do leads to over-specified layouts.
- Mobile-first means starting from the content's natural size, not "everything is 100% width." Test at the breakpoint where the layout actually fails.
- Buttons, badges, avatars, icons should be intrinsic-width — they shouldn't fill their parent. Only sections, cards, and inputs benefit from fluid sizing.
- Use `rem` for everything outside truly local typographic relationships. `em`-based components nest unpredictably.

## 7. Typography

- Pick 4–6 sizes from the type scale; ignore the rest. Inconsistency comes from too many options, not too few.
- **Body copy: 45–75 characters per line.** Use `max-w-prose` (~65ch) for paragraphs. Code blocks can go wider.
- **Line-height is proportional to size.** Body text needs 1.5+ leading. Display headings can go tight (1.0–1.2).
- **Don't center long-form text.** The left edge anchors the eye to the next line. Center single-line headings or short marketing copy, never paragraphs.
- **Right-align numbers** in columns so decimals/units stack. Add `tabular-nums` so digits have equal width.
- **Tracking rules:**
  - All-caps: loosen (`tracking-wide` or `tracking-wider`).
  - Tight display headlines: tighten (`tracking-tight`).
  - Body text: leave it alone.
- Inline links inside table cells and dense lists don't need a color — blue on every link is visual noise. Inherit color, underline on hover.

## 8. Color: HSL, ramps, intentional temperature

- **Reason in HSL, not hex.** "A bit lighter" is luck with hex and a known operation with HSL.
- **HSL, not HSB.** HSB's "brightness" axis doesn't match perception; HSL's lightness is closer.
- **You need more shades than you think:**
  - 8–10 greys covering text (95% / 80% / 60% / 40%), borders, surfaces, and dividers.
  - 1–2 primaries with 5–9 shades each.
  - 3–4 status accents with 3–5 shades each.
- **Choose the base color first**, then walk outward — find the two ends of the ramp you'll actually use, then fill in the gaps.
- **Pure HSL lightening washes color out.** Bump saturation as you lighten to keep colors alive. Tailwind's default palette is already corrected this way; that's why naive `hsl(220, 60%, 80%)` ramps look worse than `blue-300`.
- **Greys don't have to be neutral.** Tint warm (toward yellow/orange) or cool (toward blue). Pick one and stick to it.
- **Mixing warm reds and cool blues without intention looks accidental.** Decide your temperature globally.
- **Hue shifts with brightness.** A light "blue" reads greenish; a dark "blue" reads purple. Rotate hue down the ramp to compensate. Tailwind's palette does this automatically.
- **Don't rely on color alone for state.** ~8% of men have red/green colorblindness. Pair color with icon, position, weight, or label.
- **Accessible doesn't mean ugly.** WCAG AA (4.5:1 for body text) is a floor, not a ceiling. Use contrast as a constraint and choose the hue separately.

## 9. Depth: light from above, ladder of shadows

- **Pick a single light direction** (almost always top-down) and stick to it. Inconsistent shadow directions break the 3D illusion.
- **Raised elements** cast a shadow below; their top edge is slightly lighter. **Inset elements** invert this.
- **Shadows convey elevation.** Build a ladder of 3–5 steps used consistently:
  - input/border weight: `shadow-sm`
  - card: `shadow`
  - hover, raised card: `shadow-md`
  - dropdown, popover: `shadow-lg`
  - modal: `shadow-xl` or `shadow-2xl`
- **Combine shadow with interaction.** A button gaining `shadow-md` on hover feels clickable in a way a color change alone doesn't.
- **Shadows have two parts.** A tight close-in shadow ("key light") + a soft wide shadow ("ambient"). Tailwind stacks both in `shadow-md` and up.
- **Flat designs still need depth.** Color contrast, overlap, and spacing create depth without shadows.
- **Hard solid shadows** (`shadow-[8px_8px_0_#000]`) feel playful/intentional. Use sparingly.
- **Overlap elements** to create layers — a card breaking out of its container, a header pulled above its section. Overlap forces hierarchy without ambiguity.

## 10. Imagery

- **Bad stock photography kills a design faster than bad typography.** If you can't get good photos, use illustration, pattern, or nothing.
- **Text over images needs consistent contrast.** Solve with one of:
  - **Overlay** — `bg-gradient-to-t from-black/60` over the image.
  - **Lower image contrast** — image at ~70% opacity over a colored backdrop.
  - **Colorize** — monochrome-tint the image, place white text.
  - **Text shadow** — last resort; least clean.
- **Icons are designed for a specific size.** Scaling up shows jagged details; scaling down makes strokes vanish. Find a different icon, not a transform.
- **Fix the aspect ratio** with `aspect-video`, `aspect-square`, `aspect-[4/3]` so layout doesn't jump when images load.
- **Images touching colored backgrounds** often need a thin neutral border or shadow to separate; otherwise they bleed.

## 11. Polish — the difference between done and finished

- **Replace borders with depth where you can.** Borders are visual debt. Try:
  - `shadow-sm` instead — softer, modern.
  - Two background colors — the section sits on a slightly different shade.
  - Extra spacing — distance separates without lines.
- **Accent borders work better than full color fills.** A 4-pixel left border on an alert or callout is more readable than a colored background and easier to scan.
- **Surface decoration on otherwise empty areas:** SVG patterns, subtle gradients, single geometric shapes. Login backgrounds, 404 pages, and hero sections all benefit.
- **Override default OS chrome:** scrollbars, selection colors, form input borders. Defaults are visually loud; override globally, not per-component.
- **Empty states are first impressions of a feature.** Anatomy: icon or illustration + one-line headline + one-line description + primary CTA. Treat them with the design attention you give the populated state.

## 12. The signature touch

The interfaces you remember have one or two decisions you wouldn't have made by default — a surprising color choice, an oversized number, an unexpected illustration, a typographic move outside the scale. The "interesting" UI emerges from a few specific deviations, not from doing everything perfectly.

Catalog UIs you admire. Find the choices that surprise you. Steal those. A UI built entirely from defaults is a UI without a signature.

## Self-Audit Before Declaring Done

- [ ] Personality is consistent across font, color, radius, and voice
- [ ] One unambiguous primary action per screen
- [ ] Hierarchy uses size + weight + contrast in combination, no single lever overloaded
- [ ] No grey text on colored backgrounds — hand-picked hues from the same family
- [ ] Spacing comes from the system; no arbitrary `mt-[13px]`
- [ ] Spacing scale is geometric for the larger steps, not linear
- [ ] Body text is 45–75 characters per line
- [ ] Color palette has 8–10 greys, not 2 or 3
- [ ] Shadow system has 3–5 elevation steps used consistently
- [ ] Empty, loading, and error states all designed — not just the happy path
- [ ] At least one signature decision the agent wouldn't have made by default
