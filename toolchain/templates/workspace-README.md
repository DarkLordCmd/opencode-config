# <root> — engagement workspace

Everything offensive lives here. The toolchain is a Docker image (`pt/kali:latest`); nothing is
installed on the Windows host.

## Quickstart

```powershell
# first time only
powershell -ExecutionPolicy Bypass -File <root>\tools\build.ps1

# interactive Kali shell
powershell -ExecutionPolicy Bypass -File <root>\tools\pt.ps1

# single command, no shell
powershell -ExecutionPolicy Bypass -File <root>\tools\pt.ps1 -Cmd "nmap -sV -p- 10.10.0.5"

# verify what is installed
powershell -ExecutionPolicy Bypass -File <root>\tools\pt.ps1 -Cmd pt-check

# full capabilities (ligolo-ng TUN, raw sockets)
powershell -ExecutionPolicy Bypass -File <root>\tools\pt.ps1 -Privileged

# egress through a VPN/tunnel adapter (ZeroTier, WireGuard) — override the detected LHOST
powershell -ExecutionPolicy Bypass -File <root>\tools\pt.ps1 -Lhost 10.147.16.34
```

Inside the container: `/pintest` is this folder, working directory is already `/pintest`,
`PINTEST_HOME=/pintest`. Helpers: `pt-check`, `lsn <port>`, `lh` (local IP).

## Layout

```text
notes\      scope.md roe.md timeline.md inventory.md hosts\
scans\      nmap\ http\ dns\ ad\ cloud\
loot\       vault.hc (VeraCrypt, 20 GB) + README.txt — nothing else, ever   <- git-ignored
payloads\   src\ bin\
pocs\       <finding-id>\
reports\    draft\ final\ evidence-manifest.tsv
wordlists\  your own lists (SecLists is inside the container)
tools\      docker\kali\  build.ps1  pt.ps1  new-vault.ps1  bin\
tmp\
lab\        VM notes, snapshots manifest
```

Secrets live **inside the mounted volume**, not in `loot\`: mount it and use
`V:\creds`, `V:\hashes`, `V:\keys`, `V:\tickets`, `V:\screenshots`.

## Networking facts

- Reverse shells: target connects to the **Windows host IP**:4444-4450, Docker forwards into the
  container. `LHOST` is pre-set in the shell — never use the container's internal IP.
- `host.docker.internal` reaches services running on Windows (Burp listener, a local proxy).
- Ports 8080/8000/9000/9001/1080/11601 are published for payload staging, SOCKS, and ligolo.
- Scans originate from the container's NAT address, not from a dedicated exit IP. If the client
  allow-lists source IPs, tell them the host's public IP and keep `--cap-add=NET_RAW` in mind.

## Adding a tool

Edit `tools\docker\kali\Dockerfile` (required) or `install-optional.sh` (optional), then rebuild:

```powershell
powershell -ExecutionPolicy Bypass -File <root>\tools\build.ps1 -NoCache
```

Never install pentest tooling on Windows "just this once" — the image is the contract.

Image facts (measured 2026-11-06): `pt/kali:latest` = 11.1 GB, cold build 18 min, SecLists 2.6 GB /
6306 files. `pt-check` lists what is actually present; `tools\docker\kali\pt-missing-packages.txt`
inside the image records apt packages that do not exist in Kali.

## Windows-side GUI tools

GUI and driver components cannot live in the container. They are installed on the host and are
launched from `<root>\tools\bin` (already on the user PATH):

| Shim | Tool | Path |
|---|---|---|
| `burp` | Burp Suite Community 2026.3.3 | `C:\Program Files\BurpSuiteCommunity\` |
| `ghidra` | Ghidra 12.2 (portable, JDK 21) | `<root>\tools\ghidra\ghidraRun.bat` |
| `x64dbg`, `x32dbg` | x64dbg 2026.05.27 | `%LOCALAPPDATA%\Microsoft\WinGet\Packages\x64dbg.x64dbg_*\release\` |
| `accesschk`, `procdump`, `psexec`, `sigcheck` | Sysinternals Suite | `<root>\tools\sysinternals\` |
| `veracrypt` | VeraCrypt 1.26.31 | `C:\Program Files\VeraCrypt\` |

Reinstall: `powershell -ExecutionPolicy Bypass -File tools\install-gui.ps1` (needs UAC) and
`install-ghidra.ps1` (no UAC).

## Lab targets (Docker)

```powershell
docker run -d --name lab-dvwa  -p 8181:80   vulnerables/web-dvwa     # http://localhost:8181  admin/password
docker run -d --name lab-juice -p 8282:3000 bkimminich/juice-shop    # http://localhost:8282
docker stop lab-dvwa lab-juice                                       # stop, keep
docker rm   lab-dvwa lab-juice                                       # remove
```

Ports chosen to avoid the pt/kali published range (4444-4450, 8000, 8080, 9000, 9001, 1080, 11601).

## BloodHound CE (local graph analysis)

```powershell
docker compose -f <root>\tools\bloodhound\docker-compose.yml up -d
docker compose -f <root>\tools\bloodhound\docker-compose.yml logs bloodhound | Select-String "Initial Password"
# UI: http://127.0.0.1:8081/ui/login — initial admin password is printed in the logs.
# Change it immediately on first login; the default also sits in plaintext in the container logs.
docker compose -f <root>\tools\bloodhound\docker-compose.yml down       # keep graphs
docker compose -f <root>\tools\bloodhound\docker-compose.yml down -v    # wipe graphs
```

Credentials are generated per install into `tools\bloodhound\.env` (git-ignored). Only 127.0.0.1 is
published — nothing on the LAN can reach it.

## Loot encryption (manual, passphrase is yours)

The loot container exists: `<root>\loot\vault.hc` — 20 GB, AES / SHA-512 / ExFAT, created
2026-11-06. The passphrase is the operator's and is deliberately not recorded anywhere; losing it
means losing the loot. Volume creation is done by **`VeraCrypt Format.exe`**, not
`VeraCrypt.exe` (`/e` there means "open Explorer after mount"), and in CLI mode `/password` is
**mandatory** — the wizard does not prompt, it fails with "no password specified".

Use the wrapper, which asks for the phrase with masked input and passes it only to the child process:

```powershell
powershell -ExecutionPolicy Bypass -File <root>\tools\new-vault.ps1
# optional: -Path, -Size 50G, -Encryption "AES(Twofish)", -Hash sha512, -Filesystem ExFAT
```

`NTFS` triggers a UAC prompt on create, `ExFAT`/`FAT` do not. Omit `-Quick` in the script for a
slow format if the disk held sensitive data before.

Mount and unmount (the driver needs elevation, so expect UAC). `/q` makes VeraCrypt mount and exit —
the window closing is success, not a crash:

```powershell
& "C:\Program Files\VeraCrypt\VeraCrypt.exe" /q /v "<root>\loot\vault.hc" /l V
& "C:\Program Files\VeraCrypt\VeraCrypt.exe" /q /d V
```

Verify a mount without a GUI: `Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='V:'"` and
`Test-Path V:\`.

Header backup and the destruction date belong in the `reports\` cleanup appendix. **Back up the
volume header before the first engagement**: VeraCrypt → *Select File* → `vault.hc` →
*Tools* → *Backup Volume Header*. A damaged header without a backup is unrecoverable even with a
correct passphrase. Store the backup outside the container, separate from the passphrase.

## Loot hygiene

`loot\` is git-ignored and must stay encrypted at rest for client engagements (VeraCrypt container
or BitLocker on E:). Destroy per the agreement date and record it in `reports\` cleanup appendix.
