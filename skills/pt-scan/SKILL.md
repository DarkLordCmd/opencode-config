---
name: pt-scan
description: Use when scanning ports and services, fingerprinting versions, or mapping discovered hosts into an attack surface inventory — including Russian requests (сканирование портов, определение сервисов, nmap, поиск уязвимостей на хостах). Also use when deciding scan timing, rates, or how to avoid knocking a production service over.
version: 1.0.0
author: operator
tags: [offensive, scanning, nmap, enumeration, fingerprint]
---

# Scanning and Service Enumeration

Scanning is not "run nmap". It is building a **host inventory** precise enough that every later step is targeted: which service, which version, which protocol, which credential surface.

## First pass: fast discovery

```bash
# Full TCP sweep, no service detection yet — find what is open
nmap -Pn -n -p- --min-rate 2000 --max-retries 1 -T4 -oG scans/nmap/<target>-tcp.gnmap <target>

# Extract live hosts and open ports
grep -E 'Ports:' scans/nmap/<target>-tcp.gnmap | sed -E 's/.*Host: ([0-9.]+).*Ports: (.*)\/\/.*/\1 \2/'

# UDP — top ports only, it is slow and mostly useless beyond these
nmap -Pn -n -sU --top-ports 100 --max-retries 1 -T4 -oG scans/nmap/<target>-udp.gnmap <target>
```

At scale use `masscan` for discovery, then `nmap` only on open ports:

```bash
masscan -p1-65535 --rate 2000 --wait 3 -oL scans/nmap/masscan-<target>.txt <cidr>
awk '/open/{print $4}' scans/nmap/masscan-<target>.txt | sort -u > scans/nmap/hosts.txt
```

`--rate` is an impact decision, not a speed preference: 2000 pps against a production edge is noise; against a lab switch it is fine. RoE decides.

## Second pass: service detail

```bash
nmap -Pn -n -sV -sC --version-all -p<open-ports> \
     --script-timeout 60s -oA scans/nmap/<host>-detail <host>
```

Use `-oA` always: the `.xml` is what later tooling re-parses, the `.nmap` is what goes into evidence.

Targeted NSE by service:

| Service | Scripts |
|---|---|
| `smb` | `smb-os-discovery,smb-enum-shares,smb-enum-users,smb-security-mode,smb2-security-mode,smb-vuln-ms17-010` |
| `http` | `http-title,http-headers,http-methods,http-enum,http-robots.txt` |
| `ldap` | `ldap-rootdse,ldap-search` |
| `dns` | `dns-zone-transfer,dns-recursion` |
| `ssl` | `ssl-enum-ciphers,ssl-cert,ssl-heartbleed` |
| `ms-sql` | `ms-sql-info,ms-sql-config,ms-sql-empty-password` |
| `snmp` | `snmp-info,snmp-brute` |

## Version → vulnerability mapping

Do not guess. Chain: version string → CVE → exploit availability.

```bash
searchsploit --id "Apache 2.4.49"
nuclei -l scans/nmap/hosts.txt -tags cve -severity critical,high -o scans/nuclei-<engagement>.txt
nuclei -u https://<host> -t ~/nuclei-templates/http/exposures/ -o scans/nuclei-exposure.txt
```

Templates are version-fuzzy and produce false positives on patched backports. Every hit needs manual confirmation with a version-accurate check before it becomes a finding.

## Service-specific enumeration

```bash
# SMB
nxc smb <host> -u '' -p '' --shares
nxc smb <host> -u guest -p '' --users --groups --pass-pol

# LDAP anonymous bind
ldapsearch -x -H ldap://<host> -s base namingcontexts
ldapsearch -x -H ldap://<host> -b "DC=corp,DC=local" "(objectClass=user)" sAMAccountName

# NFS
showmount -e <host>
mount -t nfs <host>:/export /mnt/nfs -o nolock

# SNMP v1/v2c
onesixtyone -c community.txt <host>
snmpwalk -v2c -c public <host>

# RDP / WinRM reachability
nmap -p3389,5985,5986 --script rdp-ntlm-info,http-title <host>
```

## Inventory artifact

`notes\inventory.md` — one row per host, appended as facts land:

```markdown
| Host | IP | OS | Open services | Versions | Creds found | Access | Notes |
|------|----|----|---------------|----------|-------------|--------|-------|
| WEB01 | 10.10.0.11 | Win2019 | 80,443,445,3389 | IIS 10, SMBv3.1.1 | — | anon SMB read | shares: backups |
```

The inventory is what `pt-ad`, `pt-privesc-*`, and `pt-pivot` read next. Keep it accurate instead of keeping raw nmap output in your head.

## Timing and impact

| Situation | Flags |
|---|---|
| Lab / internal switch | `-T4 --min-rate 2000`, full `-p-` |
| Production edge, RoE allows loud | `-T3 --max-rate 500`, `-p` common then full |
| Fragile appliance / OT-adjacent | `-T2 --scan-delay 200ms`, top 1000 only |
| Stealth requested | `-T1`, `--randomize-hosts`, split across time, no `-sV` on first pass |

Signals that you are hurting something: scan duration climbing mid-run, RST spike, service health check failures, client calling you. Stop, note it, renegotiate rate.

## IPv6 and non-obvious surfaces

```bash
nmap -6 -Pn -p- <ipv6-target>
# link-local discovery on a segment
ping6 -c2 ff02::1%eth0
```

Also record: TLS SANs (new hostnames), HTTP redirects to other hosts, `Alt-Svc` headers, cloud metadata reachability.

## OPSEC

- `-Pn` skips host discovery — faster, but blind to filtering differences (a "closed" port vs dropped).
- Use `--reason` when explaining results; `filtered` vs `closed` changes the story.
- Keep one source IP for the whole engagement unless RoE says otherwise.
- Log start/stop time and exact command line per scan into `notes\timeline.md`. If the client asks "what did you run at 03:14", the answer must exist.

## Common mistakes

| Mistake | Reality |
|---|---|
| `-sV` on all 65535 ports | Hours of scanning for marginal accuracy; sweep first |
| Trusting `-sV` version banners | Banners lie or are backported; confirm behaviour |
| Scanning behind a CDN | You are hitting the edge, not the origin |
| UDP full range | Unbounded time, near-zero yield |
| Nuclei output reported as findings | Most hits need manual validation |
| No reason recorded for filtered ports | You cannot distinguish firewall from host-down later |
| Forgetting IPv6 / alternate ports (8080, 8443, 9000, 5000) | Whole apps live there |
