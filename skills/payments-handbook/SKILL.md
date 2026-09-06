---
name: payments-handbook
description: Checkout PCI scope card data boundaries - PSP tokens only pair with webhook-receivers never store or log PAN
tags:
  - payments
  - pci
  - nextjs
version: 1.0.0
category: development
outcomes:
  - PCI SAQ level self-assessment pointer merchant vs aggregator responsibilities high level
  - Client collects payment method via PSP Elements only no raw card fields in your DB
  - Webhook idempotency and amount verification checklist cross link webhook-receivers
stack:
  - next
  - typescript
last_reviewed: 2026-05-19
risk_level: high
tools_allowed: read-only
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

Plan **payments** integration with **strict PCI boundaries** and **Next.js**.

1. **Never** store **PAN**, CVV, or mag stripe data. Use **PSP-hosted fields** (card Element / Payment Element pattern) so card data touches PSP JS only.
2. **Server:** create **PaymentIntent** / session server-side with **idempotency key**; return client secret to UI; verify amounts and currency server-side on success.
3. **Webhooks:** implement with **`webhook-receivers`** - verify signature, **idempotent** event processing, handle `amount_captured` vs `metadata` order.
4. **PCI scope:** prefer **SAQ A**-style architecture (redirect or iframe/Element hosted by PSP); documenting “we never touch raw card” is required in reviews.
5. **Refunds / disputes:** outline state machine (pending → succeeded → refunded); no destructive scripts without approval.
6. **Testing:** PSP test cards only; no live keys in repo; `.env.example` keys named only.
7. **Fulfillment:** pair with **`api-handbook`** for idempotent order creation from webhook handlers.

## Outcomes

- Architecture diagram (bullet): browser → PSP → your API → DB + webhooks.
- Checklist: idempotency, verification, logging red lines.

## Output Rules

read-only design unless user explicitly requests code and approves. No real API keys.

## Scope and boundaries

- **In scope:** integration patterns, PCI boundaries, webhook pairing.
- **Out of scope:** tax/VAT legal advice, crypto on-ramp compliance, custom acquirer protocols.

## Safety

- **high** + **requires_user_approval:** true - money and compliance.
- Do not suggest storing cardholder name + PAN together in your DB.

## Troubleshooting

- **Webhook amount mismatch:** always fetch authoritative intent from PSP API before fulfilling order.
- **Client secret leaked:** rotate keys; never log client_secret.

**GitHub:** https://github.com/bh611627/skillcodex/tree/main/skills/payments-handbook/SKILL.md  
**npm:** https://www.npmjs.com/package/@skillcodex/skills
