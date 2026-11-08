---
name: pt-cred
description: Use when attacking passwords and hashes — cracking NTLM, NetNTLMv2, kerberoast and AS-REP material, password spraying within a lockout policy, credential reuse across hosts, or Responder capture — including Russian requests (брутфорс, кракинг хешей, перебор паролей, спрей паролей, hashcat). Use after hashes or a user list exist.
version: 1.0.0
author: operator
tags: [offensive, credentials, hashcat, spraying, cracking, ntlm]
---

# Credential Attacks

Three different problems that get confused: **cracking** (offline, free attempts), **spraying** (online, locked out fast), **reuse** (already have a secret, looking for where it works). Each has its own discipline and its own blast radius.

## Cracking: identify the hash, then pick a mode

| Hash | Prefix / shape | hashcat | john |
|---|---|---|---|
| NTLM | `aad3b435b51404ee...:31d6cfe0...` | `-m 1000` | `--format=nt` |
| NetNTLMv2 | `user::domain:challenge:...` | `-m 5600` | `--format=netntlmv2` |
| NetNTLMv1 | `user::domain:...` 48 hex | `-m 5500` | `--format=netntlm` |
| Kerberoast, RC4 | `$krb5tgs$23$*user$...` | `-m 13100` | `--format=krb5tgs` |
| Kerberoast, AES | `$krb5tgs$17$`/`$18$` | `-m 19700` | — |
| AS-REP | `$krb5asrep$23$user@...` | `-m 18200` | `--format=krb5asrep` |
| JWT HS256 | `eyJ...` | `-m 16500` | — |
| MSSQL / MySQL / PG | `0x0100...`, `*ABCDEF...` | `-m 1731/300/12` | — |
| KeePass | `.kdbx` | `-m 13400` | — |
| Office | `.docx/.xlsx` | `-m 9600/9500` | — |

```bash
hashcat -m 13100 loot/hashes/kerberoast.txt wordlists/rockyou.txt \
  -r rules/best64.rule -O -w 3 --status --status-timer 30
```

Strategy ladder — stop at the first hit, and stop the whole run when the time box expires:

1. **Dictionary + best64** — cheapest, catches the majority of weak service accounts.
2. **Dictionary + targeted rules** (`dive.rule`, `OneRuleToRuleThemAll.rule`), `--username` if the list has usernames.
3. **Hybrid** `-a 6` (word + digits) and `-a 7` (digits + word) for `Summer2026!` patterns.
4. **Mask** for known policy shapes: `?u?l?l?l?l?l?l?d?d?s`, `?u?l?l?l?d?d?d?d?s`.
5. **Targeted wordlist** built from the client: company name, products, city, seasons, years, keyboard walks.

```bash
# Case-mangled company wordlist before brute force
hashcat --stdout -a 1 client-words.txt rules/best64.rule > tmp/client-mangled.txt
```

GPU check before you commit: `hashcat -I`. If no GPU is available, cap expectations — CPU cracking of NetNTLMv2 at 10k H/s is not a strategy.

## Spraying: math before packets

```bash
# 1. Get the policy — threshold N attempts per window W minutes
nxc smb <dc-ip> -u '' -p '' --pass-pol

# 2. Spray exactly one password across many accounts
nxc smb <dc-ip> -u users.txt -p 'Spring2026!' -d corp.local --continue-on-success
```

Rules:

- **Attempts per account per window ≤ N − 1.** If the policy is 5/30 min, one attempt per account per 30 minutes.
- Prefer a single password per round across the whole user list over many passwords per account.
- Order candidates by real-world frequency: `Season+Year`, `Company+Year`, `Password1!`, `Welcome1`.
- Track every attempt in `notes\timeline.md`. If accounts start locking, **stop immediately** and tell the operator.
- `--continue-on-success` is mandatory — without it the first valid credential aborts the sweep.

```bash
# Local accounts, hash-based, no lockout risk of the domain policy
nxc smb <cidr> -u localadmin -H <nthash> --local-auth --continue-on-success
```

## Reuse: where does this secret work

```bash
nxc smb <cidr> -u users.txt -p 'found' --continue-on-success
nxc winrm <cidr> -u user -p 'found'
nxc rdp <cidr> -u user -p 'found'
nxc mssql <cidr> -u user -p 'found' --local-auth
nxc ssh <cidr> -u user -p 'found'
nxc ldap <dc-ip> -u user -p 'found' --admin-count
```

Also try: same password with domain vs local auth, `user@domain` vs `DOMAIN\user`, machine account passwords, and the hash itself where NTLM auth is accepted (pass-the-hash on SMB/WinRM/MSSQL).

## Capture: Responder and relay

```bash
# Analysis mode first — see who talks, without poisoning
responder -I eth0 -A

# Poisoning (LLMNR/NBT-NS/mDNS) — hashes land in Responder/logs/
responder -I eth0 -wdv
```

Rules:

- Use Responder **or** relay, not both on the same protocols — they fight for the same ports.
- `ntlmrelayx` with `-socks` turns relayed sessions into usable SOCKS entries.
- NetNTLMv1 captures crack trivially; NetNTLMv2 needs real GPU time — prefer relaying v2 and cracking v1.

## Online guessing with hydra/medusa — last resort

```bash
hydra -L users.txt -p 'Summer2026!' smb://<host> -t 1 -V    # -t 1: one at a time
```

Online brute force is loud, slow, and lockout-prone. Use it only against a service with no lockout and only when RoE allows the noise.

## Recording

```markdown
## loot\creds\CORP-jsmith.md
Source: kerberoast TGS from 10.10.0.5 (svc_sql)
Cracked: hashcat -m 13100, best64, 41 minutes, RTX 3060
Secret: <redacted in report, stored in VeraCrypt container>
Valid on: SMB 10.10.0.0/24 (7 hosts), WinRM 10.10.0.14, MSSQL 10.10.0.20 (sysadmin)
```

The `Valid on` line is what makes a credential a finding rather than a curiosity.

## Common mistakes

| Mistake | Reality |
|---|---|
| Spraying without reading `--pass-pol` | Locked-out staff, incident call, engagement damage |
| Cracking without a time box | Days of GPU time for one hash worth less than the next finding |
| Reporting "weak password" without the policy context | Severity depends on lockout, MFA, and privilege |
| Storing cracked passwords in notes | They belong in `loot\`, encrypted |
| Trying pass-the-hash where only Kerberos works | Wasted attempts, event log noise |
| Running Responder on a network with a legitimate LLMNR responder | Noise and false positives; analysis mode first |
| Assuming a cracked hash means domain access | Validate where it works before claiming impact |
