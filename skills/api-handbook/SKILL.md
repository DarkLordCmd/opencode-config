---
name: api-handbook
description: REST and Next.js Route Handler design - status codes, errors, idempotency, and versioning without bloat
tags:
  - api
  - nextjs
  - rest
version: 1.0.2
category: development
outcomes:
  - Resource-oriented URL sketch and verb map for the feature
  - Error shape convention JSON problem details or minimal stable keys
  - Idempotency notes for POST retries and webhooks
stack:
  - next
  - typescript
  - zod
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

Shape **HTTP APIs** implemented as **Next.js Route Handlers** (or edge/node runtime).

1. Model resources and sub-resources; prefer nouns in paths; version in path or header - pick one and document.
2. Status codes: 200/201/204/400/401/403/404/409/422/429/500 - when to use each for this feature.
3. **Errors:** consistent JSON body; never leak stack traces in production responses.
4. **Idempotency:** `Idempotency-Key` for creates; safe retries for PATCH.
5. **Validation:** zod at boundary; typed handler args.
6. **Rate limiting:** mention middleware or external gateway - do not invent product names.
7. **CORS:** if handlers are called from browsers, define explicit `Access-Control-Allow-Origin` (never `*` with credentials); prefer same-origin BFF pattern for cookie sessions.
8. **Security headers:** align with `security-headers` for APIs that return HTML or are hit by browsers; JSON-only APIs still benefit from `X-Content-Type-Options: nosniff`.
9. **Realtime:** for SSE/WebSockets see **`realtime-handbook`** - do not overload REST handlers with long-lived streams without that skill’s checks.

## Outcomes

- Verb + path table, error contract, idempotency bullets.

## Output Rules

Tables first; then optional example handler signature pseudocode only.

## Scope and boundaries

- **In scope:** Route Handler design, contracts, headers.
- **Out of scope:** GraphQL schema design, gRPC, legacy PHP APIs.

## Safety

- Read-only; no real API keys in examples.

## Troubleshooting

- **405 on route:** check `export const dynamic` vs method exports.
- **Body parse errors:** validate content-type and zod schema order.

**GitHub:** https://github.com/bh611627/skillcodex/tree/main/skills/api-handbook/SKILL.md  
**npm:** https://www.npmjs.com/package/@skillcodex/skills
