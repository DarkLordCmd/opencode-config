# Rules of Engagement — <client>

> Copy to `notes\roe.md` and fill. Mirrors the template in the `pt-scope-roles` skill.

## Allowed techniques

- Port scanning, service enumeration, web fuzzing (rate-limited)
- Authentication attacks within lockout policy: max <N> attempts per account per <period>
- Credential reuse, password spraying at <N> accounts/hour
- Exploitation to prove impact (RCE proof = id/whoami, no further action)
- AD enumeration, kerberoasting, ADCS abuse

## Prohibited techniques

- DoS / resource exhaustion / fuzzing that degrades service
- Persistence beyond the test window
- Modifying or deleting business data
- Ransomware simulation, wiper behaviour
- Targeting employees' personal accounts or devices

## Rate and detection

- Web: <N> req/s · Scans: <N> packets/s
- Blue-team awareness: full | partial | none
- Pause conditions: IDS block, service error spike, client call

## Data handling

- Screenshots may contain PII → redact before report
- Credentials stored in `V:\` (VeraCrypt vault), never in `E:\pintest\loot\`
- No client data leaves `E:\pintest\<engagement>\`
- Destruction of container + header backup due: <date>

## Deliverables

Daily status note | Weekly call | Final report <date> | Retest window <dates>
