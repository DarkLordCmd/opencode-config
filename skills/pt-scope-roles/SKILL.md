---
name: pt-scope-roles
description: Use when starting or renegotiating a security engagement and the authorization, scope boundaries, test window, escalation contacts, deconfliction rules, or data-handling constraints must be written down — including Russian requests (согласование скоупа, правила взаимодействия, рамки теста, разрешение на тестирование). Also use before the first packet when scope is undocumented.
version: 1.0.0
author: operator
tags: [offensive, pentest, scope, roe, legal, engagement]
---

# Scope and Rules of Engagement

Phase 0. Everything downstream inherits its boundaries from these two files. Getting this wrong does not make the test less effective — it makes it unauthorised.

## Overview

Two documents, both written before any traffic reaches a target:

- `notes\scope.md` — **what** may be touched.
- `notes\roe.md` — **how and when** it may be touched.

If either is missing details, collect them from the operator once, in one block of questions, then proceed.

## scope.md — template

```markdown
# Scope — <client> — <engagement-id>

Authorization: <letter ref / SOW / bug-bounty program URL>
Signed by: <name, role>            Date: <date>
Engagement type: black-box | grey-box | white-box | red team | assumed breach
Test window: <start> .. <end>, <timezone>, allowed hours <hh:mm-hh:mm>

## In scope
| Type | Target | Notes |
|------|--------|-------|
| CIDR | 10.10.0.0/24 | prod web tier only |
| Host | app.client.com | all paths except /billing |
| App | https://portal.client.com | account: pentest01..05 provided |
| Cloud | AWS acct 1234... | read-only enumeration role |
| API | /api/v2/* | token issued 2026-xx-xx |

## Out of scope
- 10.10.5.0/24 (OT network) — hard exclusion
- Third-party SaaS and payment processors (Stripe, Auth0)
- Denial of service, stress testing, load > 5 rps
- Social engineering / phishing against staff
- Physical access attempts
- Destructive DB operations (DROP, TRUNCATE, mass UPDATE)
- Data exfiltration beyond 10 records per finding (proof only)

## Escalation
Primary contact: <name> <phone> <email>
Emergency stop signal: <phrase or code word>
Out-of-hours contact: <...>
Incident path if a test breaks something: stop, preserve logs, call primary.
```

Scope entries must be **enumerable**. "The corporate network" is not a scope; a CIDR list is.

## roe.md — template

```markdown
# Rules of Engagement — <client>

## Allowed techniques
- Port scanning, service enumeration, web fuzzing (rate-limited)
- Authentication attacks within lockout policy: max <N> attempts per account per <period>
- Credential reuse, password spraying at <N> accounts/hour
- Exploitation to prove impact (RCE proof = id/whoami, no further action)
- AD enumeration, kerberoasting, ADCS abuse in a lab replica first if provided

## Prohibited techniques
- DoS / resource exhaustion / fuzzing that degrades service
- Persistence beyond the test window
- Modifying or deleting business data
- Ransomware simulation, wiper behaviour
- Targeting client employees' personal accounts or devices
- Bypassing monitoring without notifying the blue team when agreed

## Handling rules
- Rate limit: <N> req/s for web, <N> packets/s for scans
- Source IPs disclosed in advance: <list or "not disclosed">
- Blue-team awareness: full | partial | none (deconfliction on detection)
- Pause conditions: IDS block, service error spike, client call

## Data handling
- Screenshots may contain PII → redact before report
- Credentials stored encrypted (`VeraCrypt` container in `loot\`), destroyed <date> after close
- No client data leaves `E:\pintest\<engagement>\`
- Destruction confirmation due: <date>

## Deliverables and cadence
Daily status note | Weekly call | Final report <date> | Retest window <dates>
```

## Pre-flight checks

Run these before phase 1 and record the result in `notes\timeline.md`:

- [ ] Authorization document present, references this engagement ID, signed and dated
- [ ] In-scope list is concrete and copy-pasteable
- [ ] Out-of-scope hard exclusions noted (OT, third parties, personal devices)
- [ ] Test window and timezone confirmed
- [ ] Escalation contacts reachable *today* (send a test message)
- [ ] Rate limits and lockout policy known
- [ ] Source IPs agreed (yours for allow-listing, or intentionally not disclosed)
- [ ] Cloud/provider terms checked if testing SaaS-hosted infrastructure
- [ ] Data-destruction obligation and date recorded

## Grey-box requests to make early

Missing these wastes days later:

- Test accounts and their privilege levels; at least one account per role
- API tokens / service credentials
- Architecture diagram or at minimum the external IP inventory
- Known-good findings from the last assessment (avoid re-reporting solved issues)
- Change-freeze windows, Black Friday / month-end blackout dates

## Deconfliction

- **Detection is expected.** Agree what happens when blue team sees you: continue, pause, or identify yourself.
- **If a test degrades a service:** stop, capture evidence, notify primary contact, write it in the timeline. Do not "wait and see".
- **If you find evidence of a real, active compromise** (someone else's shell, unknown admin account): stop, preserve, escalate — this is no longer a pentest task.

## Common mistakes

| Mistake | Fix |
|---|---|
| Scope inherited verbally | Written scope with signer and date, always |
| Testing a domain that resolves to a CDN | Confirm origin vs edge; CDN hosts are third-party |
| "Just one extra host to confirm" | Out of scope is out of scope; request an amendment in writing |
| No rule for credential attacks | Explicit attempt counts and lockout threshold |
| Report mentions out-of-scope host | Leak of unauthorised access; scrub and disclose to operator |
| Loot kept after project close | Destruction confirmation is part of delivery |
