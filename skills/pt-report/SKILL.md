---
name: pt-report
description: Use when writing or assembling a penetration test deliverable — findings with severity and CVSS, proof-of-concept steps, executive summary, evidence manifest, retest results, cleanup confirmation, or client-ready PDF/DOCX — including Russian requests (отчёт по пентесту, оформить находки, severity, executive summary). Use from the first finding onward, not only at the end.
version: 1.0.0
author: operator
tags: [offensive, pentest, reporting, cvss, deliverable, evidence]
---

# Reporting

The report is the deliverable. A finding that cannot be reproduced by the client's engineer is not a finding — it is an opinion. Write each finding **when you find it**, in the final shape, into `reports\draft\`.

## Finding format (fixed)

```markdown
### WEB-03 — Broken object-level authorization on invoice API

**Severity:** High  **CVSS:** 3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N (7.1)
**Component:** portal.client.com, /api/v1/invoices/{id}, build 2026.09.14
**Status:** Confirmed

**Summary**
Any authenticated user can read any other tenant's invoice by changing the numeric id. No
authorization check is performed on the object owner.

**Precondition**
Two accounts at the same role (pentest01, pentest02) issued by the client.

**Reproduction**
1. Authenticate as pentest01, create invoice, note id 1041.
2. Authenticate as pentest02, obtain token.
3. `curl -H "Authorization: Bearer $T2" https://portal.client.com/api/v1/invoices/1041`

**Observed**
HTTP 200, invoice body of pentest01 including name, address, tax id, amount.

**Expected**
HTTP 403 or 404 for a resource not owned by the caller.

**Impact**
Cross-tenant disclosure of billing and tax identifiers. At 5 000 invoices/day, the whole
billing table is enumerable with a single script in under an hour.

**Evidence**
`pocs/WEB-03/request.txt`, `pocs/WEB-03/response.txt`, `pocs/WEB-03/screenshot.png`

**Remediation**
Enforce ownership at the data layer: scope every query by `tenant_id` from the authenticated
principal, not by the id supplied by the client. Add a regression test with two tenants.
Priority: immediate.

**Retest**
Pending — target window 2026-12-01 .. 2026-12-05.
```

Sections are mandatory. "Description" without "Reproduction" and "Observed" is a rejected finding.

## Severity — decide by consequence, not by exploit difficulty

| Severity | Criteria | Examples |
|---|---|---|
| Critical | Direct path to broad compromise or mass sensitive-data access, no user interaction | Pre-auth RCE, domain admin from unauthenticated, SQLi dumping all customers |
| High | Serious confidentiality/integrity/availability loss, limited preconditions | Authenticated RCE, cross-tenant data access, admin panel auth bypass |
| Medium | Real impact requiring specific conditions or low-value data | Stored XSS with session theft potential, IDOR on internal documents, local privesc to service account |
| Low | Limited impact, defence-in-depth, needs unlikely conditions | Missing security headers with an exploitable consequence spelled out, verbose errors without secrets |
| Info | Observation, no demonstrated impact | Version disclosure, directory listing of public assets |

Rules:

- Compute CVSS honestly, then sanity-check against the table. A 9.8 on paper with "requires phishing plus local admin" is not critical.
- **Do not inflate for the invoice and do not deflate to look calm.** State what was proven and what remains assumption.
- Chain findings: three mediums that combine into domain takeover are one critical with a chain diagram.

## Report structure

```text
reports\final\<client>-pentest-<date>.pdf
1. Cover — engagement id, dates, version, classification
2. Executive summary — 1 page, no jargon: what we tested, what we found, top 3 risks,
   what to fix first, overall posture sentence
3. Scope and methodology — from notes\scope.md and notes\roe.md, techniques used, limitations
4. Findings — Critical → Info, each in the fixed format
5. Attack narrative (optional) — the chain as a story, for red-team engagements
6. Remediation roadmap — grouped by effort/impact, not by severity alone
7. Retest results — what was fixed, what was not, residual risk
8. Appendix — tooling, host inventory, evidence manifest, cleanup confirmation
```

The executive summary is written for someone who will read **only** that page. One sentence per finding maximum, and a recommendation they can act on this quarter.

## Evidence discipline

- Every finding references files by relative path under `pocs\<ID>\`.
- `reports\evidence-manifest.md` carries `path | sha256 | captured-at | host | description`.
- Screenshots: redact PII and credentials before they enter `reports\`. Redaction is done on a copy, never the original.
- Hash the originals at capture time (`Get-FileHash`), so the manifest proves nothing changed later.

```powershell
Get-ChildItem pocs -Recurse -File | ForEach-Object {
  $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
  "{0}`t{1}`t{2}" -f $_.FullName.Replace((Get-Location).Path + '\',''), $h, $_.LastWriteTime
} | Out-File reports\evidence-manifest.tsv -Encoding utf8
```

## Cleanup confirmation

Mandatory appendix. A list, each item with a status:

- [ ] Uploaded files, webshells, and payloads removed from every host
- [ ] Accounts, users, computer objects, and service principals created during the test removed
- [ ] Scheduled tasks, services, registry keys, cron entries reverted
- [ ] Kerberos tickets and injected sessions terminated
- [ ] C2 redirectors and teamserver torn down; domains released
- [ ] Client data destroyed per the agreement, with the date and method recorded
- [ ] Client notified of anything that could not be reverted, in writing

## Retest

```markdown
## Retest — 2026-12-03
| Finding | Status | Note |
|---|---|---|
| WEB-03 | Fixed | 403 returned for cross-tenant id; verified with same account pair |
| AD-01 | Partially fixed | ADCS template hardened, but ESC8 endpoint still open |
| PAY-02 | Accepted risk | Client documented compensating control |
```

Re-run the exact original PoC. A retest that uses a new technique proves nothing about the old finding.

## Common mistakes

| Mistake | Reality |
|---|---|
| Writing findings at the end from memory | Details lost, PoCs unreproducible, timeline wrong |
| Severity by gut feeling | Client disputes it; use a rubric and CVSS |
| Executive summary full of CVE ids | The reader does not care; state business consequence |
| Screenshots with live credentials | Leak in a document that gets emailed around |
| No "Expected" section in a finding | Client cannot tell what correct behaviour is |
| Missing cleanup appendix | Unexplained persistence becomes an incident |
| Retest with a different payload | Does not prove the original path is closed |
