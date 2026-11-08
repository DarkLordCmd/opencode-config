# Scope — <client> — <engagement-id>

> Copy to `notes\scope.md` and fill. Mirrors the template in the `pt-scope-roles` skill.
> No packet leaves the host until this file exists and is signed off.

Authorization: <letter ref / SOW / bug-bounty program URL>
Signed by: <name, role>            Date: <date>
Engagement type: black-box | grey-box | white-box | red team | assumed breach
Test window: <start> .. <end>, <timezone>, allowed hours <hh:mm-hh:mm>

## In scope

| Type | Target | Notes |
|------|--------|-------|
| CIDR | | |
| Host | | |
| App | | |
| Cloud | | |
| API | | |

## Out of scope

- 
- Third-party SaaS and payment processors:
- Denial of service / load limits:
- Social engineering:
- Destructive data operations:

## Escalation

Primary contact: <name> <phone> <email>
Emergency stop signal: <phrase or code word>
Out-of-hours contact:
Incident path if a test breaks something: stop, preserve logs, call primary.

## Access provided

| Item | Value | Note |
|---|---|---|
| VPN / allow-list | | |
| Accounts (per role) | | |
| API tokens | | |
| Source IPs disclosed | | |
