---
name: security-headers
description: HTTP security headers and CSP for Next.js - safe defaults, nonces, and report-only rollout
tags:
  - security
  - nextjs
  - csp
version: 1.0.0
category: development
outcomes:
  - Header set table with values suited to Next static and dynamic routes
  - CSP directive list separating script style img connect fonts
  - Rollout plan report-only first then enforce
stack:
  - next
  - typescript
last_reviewed: 2026-05-19
risk_level: medium
tools_allowed: repo-files
requires_user_approval: true
compatibility:
  - cursor
  - claude-code
  - skills-sh
  - generic-markdown
references:
  - references/skill-safety.md
  - references/stack-nextjs.md
---

# Instructions

Design **CSP** and companion headers (`HSTS`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`, `COOP`) for **Next.js**.

1. Inventory inline scripts and styles; decide **nonce** vs hash strategy for App Router.
2. Start **Content-Security-Policy-Report-Only** with `report-to` or `report-uri` if used.
3. Third parties: list each script domain in `script-src`; avoid `unsafe-inline` unless documented exception.
4. `next.config` headers vs middleware - match deployment (Vercel self-hosted).
5. Document break-glass: how to widen policy for emergency hotfix.

## Outcomes

- Header table + CSP lines + rollout steps.

## Output Rules

Fenced blocks for `next.config` header snippets only after user approves writes.

## Scope and boundaries

- **In scope:** headers, CSP, Permissions-Policy for frontend.
- **Out of scope:** WAF vendor rules, DDoS provider setup.

## Safety

- **requires_user_approval:** true - wrong CSP breaks production.
- Never paste real nonce secrets; use placeholders.

## Troubleshooting

- **CSP blocks hydration:** check nonce on `next/script` strategy.
- **Images blocked:** add `img-src` and `media-src` as needed.

**GitHub:** https://github.com/bh611627/skillcodex/tree/main/skills/security-headers/SKILL.md  
**npm:** https://www.npmjs.com/package/@skillcodex/skills
