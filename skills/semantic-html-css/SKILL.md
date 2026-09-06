---
name: semantic-html-css
description: Semantic HTML, landmarks, focus, and modern CSS - fast accessible UI that pairs with WCAG audits
tags:
  - html
  - css
  - accessibility
version: 1.0.0
category: development
outcomes:
  - Landmark map main nav aside for the layout in question
  - Heading outline h1 per view logical order
  - CSS checklist focus-visible containment prefers-reduced-motion
stack:
  - html
  - css
  - react
  - tailwindcss
last_reviewed: 2026-05-19
risk_level: low
tools_allowed: read-only
requires_user_approval: false
compatibility:
  - cursor
  - claude-code
  - skills-sh
  - generic-markdown
references:
  - references/design-guidelines.md
  - references/skill-safety.md
---

# Instructions

Raise baseline **HTML semantics** and **CSS quality** before or alongside `accessibility-audit`.

1. **Landmarks:** one `main`; `nav` for primary nav; `header`/`footer` roles clear; skip redundant `role` when native element suffices.
2. **Headings:** single logical `h1` per page/view; no level skips for styling - fix with CSS.
3. **Interactive:** native `button` vs `div` onClick; `a` with real `href` for navigation; hit targets ≥ 24px (prefer 44px touch).
4. **Focus:** `:focus-visible` styles never removed without replacement; no `outline: none` without visible focus ring.
5. **Motion:** `prefers-reduced-motion: reduce` - replace auto-play loops with static or instant state.
6. **Layout:** prefer `flex`/`grid` + `gap`; avoid deep absolute positioning for primary reading flow.

## Outcomes

- Bullet list of markup fixes + CSS tokens to add (spacing, focus ring color).

## Output Rules

File:line when auditing existing code; for greenfield, component tree with element types.

## Scope and boundaries

- **In scope:** structure, global CSS patterns, Tailwind class-level guidance.
- **Out of scope:** full color-system design (use `web-design-guidelines`).

## Safety

- read-only unless user requests edits.

## Troubleshooting

- **Landmark duplication:** multiple `main` from portals - consolidate or `aria-hidden` on duplicate decorative wrappers only with care.

**GitHub:** https://github.com/bh611627/skillcodex/tree/main/skills/semantic-html-css/SKILL.md  
**npm:** https://www.npmjs.com/package/@skillcodex/skills
