---
name: skillcodex-browser-ui
description: Full SkillCodex doc browser - skills.sh-style UI, STRICT UI only, design-guidelines
tags:
  - ui
  - nextjs
  - skillcodex
version: 1.5.0
category: development
outcomes:
  - Four routes live with skeletons and skills.sh gaps filled (outcomes, copy, create, guidelines)
  - Apple-level whitespace doc UI using Tailwind + framer-motion
stack:
  - pnpm
  - next
  - react
  - typescript
  - tailwindcss
  - framer-motion
  - react-icons
last_reviewed: 2026-05-16
risk_level: medium
tools_allowed: suggest-shell
requires_user_approval: false
compatibility:
  - generic-markdown
  - cursor
  - claude-code
  - skills-sh
references:
  - references/design-guidelines.md
  - references/data-source.md
  - references/react-stack.md
---

# Instructions

Build full doc browser per [design-guidelines.md](../../references/design-guidelines.md). For component-level design work use [web-design-guidelines](../web-design-guidelines/SKILL.md) first.

**STRICT UI ONLY** - no backend, API, DB, or auth.

**Package manager:** pnpm for new app; match user lockfile if project exists.

**Stack:** Next, TS, Tailwind, **framer-motion**, react-markdown, remark-gfm, react-icons.

Fill [skills.sh](https://www.skills.sh/) gaps: outcomes on detail, full markdown, create page, guidelines, skeletons, URL pagination, no fake install counts.

Data: [data-source.md](../../references/data-source.md).

## Outcomes

- `/`, `/skills/[slug]`, `/create`, `/guidelines` with `pnpm dev`
- Checklist in design-guidelines passed

## Output Rules

Data source, file tree, checklist, `pnpm dev`.

## Scope and boundaries

- Documentation browser only - not SaaS landing or dashboard.

## Safety

- User runs pnpm; mock data only if no skills provided.

## Troubleshooting

- **framer-motion in layout:** only import motion in client leaf components.
- **pnpm vs npm lockfile mismatch:** use the lockfile already in the repo.
- **Fake install counts:** show outcomes and tags, not download metrics.

**GitHub:** https://github.com/bh611627/skillcodex/tree/main/skills/skillcodex-browser-ui/SKILL.md  
**npm:** https://www.npmjs.com/package/@skillcodex/skills
