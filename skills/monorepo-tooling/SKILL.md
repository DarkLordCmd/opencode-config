---
name: monorepo-tooling
description: pnpm workspaces and Turborepo with Next.js apps - boundaries caching and shared packages
tags:
  - monorepo
  - pnpm
  - turborepo
version: 1.0.0
category: development
outcomes:
  - Workspace package graph description apps packages tooling
  - turbo pipeline keys for lint test build with dependsOn
  - Guidance on env and next transpilePackages when needed
stack:
  - pnpm
  - turbo
  - next
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
  - references/stack-nextjs.md
  - references/skill-safety.md
---

# Instructions

Structure **pnpm workspaces** + **Turborepo** for one or more **Next.js** apps and shared packages.

1. Define `pnpm-workspace.yaml` globs; separate `apps/*` and `packages/*`.
2. `turbo.json` pipelines: `build` depends on `^build`; cache outputs for Next `.next` and dist folders.
3. **Internal packages:** TypeScript project references or `transpilePackages` in Next when consuming local UI libs.
4. **Env:** root vs app `.env`; never duplicate secrets in git.
5. **Versioning:** single lockfile; align Node engine field.

## Outcomes

- Folder tree + `turbo.json` task outline + pnpm filter examples.

## Output Rules

Commands use `pnpm` and `turbo` only; match user lockfile if mixed.

## Scope and boundaries

- **In scope:** workspace layout, turbo pipelines, Next consumption of local packages.
- **Out of scope:** Nx-specific generators, Bazel.

## Safety

- Read-only unless editing config files is explicitly requested.

## Troubleshooting

- **Module not found across workspace:** check `package.json` `exports` and TypeScript paths.
- **Turbo cache too aggressive:** `outputs` keys wrong for Next - fix globs.

**GitHub:** https://github.com/bh611627/skillcodex/tree/main/skills/monorepo-tooling/SKILL.md  
**npm:** https://www.npmjs.com/package/@skillcodex/skills
