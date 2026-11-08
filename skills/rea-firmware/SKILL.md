---
name: rea-firmware
description: Use when working with firmware or embedded devices — extracting and unpacking a firmware image, recovering a base load address, parsing BIOS/UEFI updates, emulating a device, or debugging a microcontroller — including Russian requests (прошивка, разбор firmware, UEFI, BIOS, распаковать образ, эмуляция устройства). Catalogue-driven.
version: 1.0.0
author: operator
tags: [reverse-engineering, firmware, embedded, uefi, binwalk, hardware]
---

# Firmware and hardware

89 firmware-targeted entries (71 in the firmware category). The hard part is rarely the filesystem —
it is finding where the image starts, what architecture it is, and how to run it without the device.

```bash
python3 scripts/catalog.py --target firmware
python3 scripts/catalog.py "uefi" --target firmware --json
```

## Extraction and structure

| Tool | URL | Purpose |
|---|---|---|
| Binwalk | https://github.com/ReFirmLabs/binwalk | find embedded formats, extract, entropy analysis |
| binbloom | https://github.com/quarkslab/binbloom | infer properties of a headerless raw image |
| basefind2 | https://github.com/soyersoyer/basefind2 | estimate load address without brute force |
| allyourbase | https://github.com/8051Enthusiast/allyourbase | base address from string-address correlation |
| Bin X-ray | https://github.com/russlank/BinXray | visualise byte patterns in an unknown blob |
| BIOSUtilities | https://github.com/platomav/BIOSUtilities | 16 parsers for vendor BIOS/UEFI update formats |
| Aptio V UEFI Editor | https://github.com/BoringBoredom/UEFI-Editor | edit AMI Aptio V setup menus |

Typical order: `binwalk` (what is inside) → `binbloom`/`basefind2` (where it loads) → carve
filesystems → identify the OS/RTOS → continue in `rea-native`.

Vendor-specific images (JieLi, Espressif, Realtek…) usually have a dedicated unpacker in the catalogue
— search by the chip or vendor name before writing one.

## Emulation and debugging

| Tool | URL | Purpose |
|---|---|---|
| avatar2 | https://github.com/avatartwo/avatar2 | orchestrate emulators, debuggers and real devices |
| Black Magic Debug | https://codeberg.org/blackmagic-debug/blackmagic | self-contained MCU debugger probe |

Emulation beats a real device for iteration; keep a hardware path for anything timing- or
peripheral-dependent.

## Playbook

1. **Hash the image** and record the source (vendor page, SPI dump, update file).
2. **Identify the container**: vendor header, UEFI capsule, squashfs+custom, encrypted blob.
3. **Recover the base address** before disassembling — wrong base makes every reference nonsense.
4. **Carve and mount** filesystems read-only; extract configs, keys, scripts, web roots.
5. **Find the attack surface**: management ports, hardcoded credentials, updater signature checks.
6. **Emulate** the userland if the CPU is supported; otherwise work statically.
7. **Record** the extraction chain in notes so the result is reproducible.

## Safety

Flashing modified firmware bricks devices and can violate warranty and law. Do extraction and
emulation on copies; only write to hardware when the owner asked for it and a recovery path exists.

## Common mistakes

| Mistake | Reality |
|---|---|
| `binwalk -e` and done | Extraction succeeds, structure is still unknown |
| Disassembling at offset 0 | Most images load at a base you have not found yet |
| Assuming Linux | Many devices are bare-metal or an RTOS with no symbols |
| Testing on the only device | Bricking it ends the engagement |
