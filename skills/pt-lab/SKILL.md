---
name: pt-lab
description: Use when building, resetting, or isolating a practice or replication lab — vulnerable VMs, Active Directory range, snapshot discipline, host-only networking, detonation of payloads — including Russian requests (лаборатория, стенд, полигон, изолированная сеть, снапшоты). Use whenever a payload, exploit, or kernel-level action must be tested before a real target.
version: 1.0.0
author: operator
tags: [offensive, lab, vmware, isolation, snapshots, testing]
---

# Lab

Lab exists so production never becomes the test environment. Everything here lives under `E:\pintest\lab\` — notes, snapshots manifests, and VM inventory.

## Host capability check

```powershell
# What this machine already has
Get-Command vmrun                                    # VMware Workstation
(Get-CimInstance Win32_ComputerSystem).HypervisorPresent
Get-PSDrive E | Select-Object Name,@{n='FreeGB';e={[math]::Round($_.Free/1GB,1)}}
```

VMware Workstation is installed; `E:` has ~590 GB free — enough for an AD range (4–6 VMs) plus vulnerable targets.

## Isolation rules

1. **Host-only or custom isolated vSwitch only.** Never bridged for a range containing vulnerable machines.
2. `nat` is acceptable only for patch downloads, and disabled during detonation.
3. **No shared folders** between host and vulnerable VMs; drag-and-drop and clipboard disabled in VM settings.
4. The lab must be unable to reach `10.0.0.0/8`, the operator's LAN, or the internet when a payload is detonated.
5. Document the layout in `lab\lab-map.md` — every VM, its network, and its purpose.

## Building the range

| Purpose | Image |
|---|---|
| AD domain (domain controller + 2 clients) | Windows Server 2019/2022 eval + Windows 10/11 eval |
| Linux targets | Ubuntu Server LTS, Debian + DVWA/Juice Shop, Metasploitable 2/3 |
| Web targets | OWASP Juice Shop (docker), DVWA (docker), bWAPP |
| Detection / blue-team replication | Sysmon + a SIEM, or a small Elastic/Wazuh stack |
| AD attack practice | GOAD (Game of Active Directory) — automated, resettable |

```bash
# Fast web targets with Docker — no VM needed
docker run -d -p 3000:3000 bkimminich/juice-shop
docker run -d -p 8080:80 vulnerables/web-dvwa
```

## Snapshot discipline

Snapshot **before** every exploit attempt that can crash or corrupt a host.

```powershell
$vmx = "E:\pintest\lab\vms\WS01\WS01.vmx"
& "C:\Program Files\VMware\VMware Workstation\vmrun.exe" snapshot $vmx "clean-baseline"
& "C:\Program Files\VMware\VMware Workstation\vmrun.exe" revertToSnapshot $vmx "clean-baseline"
& "C:\Program Files\VMware\VMware Workstation\vmrun.exe" listSnapshots $vmx
```

Rules:

- One snapshot named `clean-baseline` that is never written over.
- Per-attempt snapshots named `<date>-<technique>`.
- Kernel exploits, driver loading, and payload detonation always start from `clean-baseline`.
- Record the snapshot list in `lab\snapshots.md` so a revert is not guesswork.

## Payload detonation

- Defender **on** in the detonation VM when testing evasion — otherwise you are testing nothing.
- Host's Defender exclusion for `E:\pintest` is a host-only convenience; it does not tell you anything about the payload.
- Detonate from an isolated attacker VM, not from the host, so the network telemetry is realistic.
- Capture: process tree, Sysmon EventID 1/3/8/10/11, Defender detection name (`Get-MpThreatDetection`).

## Reset procedure

```text
1. Revert every VM touched to its last known-good snapshot
2. Delete dropped files, scheduled tasks, and users created during the test
3. Re-run the baseline health check (domain join, service running, target reachable)
4. Note the reset in lab\lab-map.md with timestamp
```

A lab that is not reset becomes a source of false results — "it worked" on a machine that still has yesterday's loader on disk.

## Common mistakes

| Mistake | Reality |
|---|---|
| Bridged networking "temporarily" | One misconfigured target and the LAN is exposed |
| No baseline snapshot | Rebuilding the DC from scratch after a botched exploit |
| Testing payloads with Defender disabled | Proves nothing about real detection |
| Shared clipboard/folders to vulnerable VMs | Malware and stolen creds cross into the host |
| Lab state never reset | Inconsistent results, wasted hours |
| Range without documentation | Nobody can reproduce or extend it |
