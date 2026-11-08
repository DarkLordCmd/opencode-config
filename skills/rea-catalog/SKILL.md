---
name: rea-catalog
description: Use when reverse engineering is on the table — inspecting shipped software, deobfuscating web bundles, unpacking game or app packages, analysing native binaries, firmware, or wire protocols — and a tool, case study, or prior art is needed before writing anything from scratch, including Russian requests (реверс-инжиниринг, реверс, разбор бинарника, распаковка, деобфускация, разбор протокола). Entry point to the REA catalogue and its six domain skills.
version: 1.0.0
author: operator
tags: [reverse-engineering, rea, catalog, router, tooling]
---

# REA Catalogue — router

A curated, reviewed catalogue of **1,253 resources** (431 case studies, 235 papers) covering reverse
engineering of websites, games, apps, native binaries, firmware and protocols. The point is to stop
inventing tooling: before writing a parser or a deobfuscator, check whether someone already did it and
what its limits are.

**Local copy:** `E:\pintest\tools\awesome-rea` (62 MB, snapshot of 2026-11-06).
**Upstream:** `https://github.com/reacher-z/Awesome-REA` · site `https://awesomerea.org/`.

## Query the catalogue

Run inside the pt container (Python 3 is already there):

```bash
cd /pintest/tools/awesome-rea
python3 scripts/catalog.py "frida" --target app          # free-text search
python3 scripts/catalog.py --target firmware             # everything for a domain
python3 scripts/catalog.py --list-categories             # exact category names
python3 scripts/catalog.py "obfuscation" --json          # full records with provenance
python3 scripts/catalog.py "protobuf" --source-index     # unreviewed repo index (3,309 entries)
python3 scripts/catalog.py "unity" --language zh         # Chinese descriptions
```

Filter flags: `--target website|game|app|binary|firmware|protocol`, `--category <exact>`,
`--relationship <exact>`, `--language en|zh`, `--json`, `--source-index`.

## Record fields that matter

| Field | Meaning |
|---|---|
| `verification` | `source-reviewed` = documentation was read. **Not** runtime-tested, not compatibility-checked |
| `evidence_url` | Pinned commit link — cite this, not the repo root |
| `verified_at` | Date of review; older dates may describe an older version |
| `requirements` | Real constraints (JDK, Node, licence, hardware, signing) — read before promising anything |
| `targets`, `category` | Domain and function; use them to route |
| `relationship` | How it relates to REA (independent, community, official…) |

## Routing

| The thing to inspect | Skill |
|---|---|
| JavaScript bundles, minified SPA, browser extensions, Electron asar | `rea-website` |
| Unity/Unreal/Source games, assets, IL2CPP, modding, matching decomp | `rea-game` |
| Android APK, .NET assembly, JVM jar, Electron, Flutter, HarmonyOS | `rea-app` |
| ELF/PE/Mach-O, disassembly, decompilation, diffing, symbolic execution | `rea-native` |
| Firmware images, BIOS/UEFI, embedded devices, base address recovery | `rea-firmware` |
| Wire formats, BLE/CAN, protobuf, custom TCP/UDP, capture analysis | `rea-protocol` |
| Agent integrations, MCP servers for RE tools | below |

## Agents and MCP

The catalogue tracks 87 agent-related entries (`--category agent-mcp`). They are labelled by
relationship, and the label is not a quality claim: an MCP server existing does not mean it works with
your tool version. Check `requirements` and `verified_at`, and test before relying on it.

```bash
python3 scripts/catalog.py --category agent-mcp --target binary --json
```

## Evidence discipline

1. **`source-reviewed` is a documentation fact.** Never write "supports X" in a report because the
   catalogue says so — run it, or write "по документации, не проверено".
2. **Cite pinned evidence.** `evidence_url` already points to a commit; use it instead of `main`.
3. **Check the licence before shipping anything** built on a catalogue entry. Several entries carry
   licence caveats in `requirements`.
4. **Record what you actually ran**: version, command, result — in the engagement notes.
5. If the catalogue has nothing, say so and fall back to first principles; do not dress up a guess as
   prior art.

## Common mistakes

| Mistake | Reality |
|---|---|
| Treating the catalogue as a recommendation | It is an index with review dates, not a ranking |
| Skipping `requirements` | Most "broken" tools fail on a missing runtime, not on logic |
| Quoting `main` URLs | Line numbers drift; cite the pinned `evidence_url` |
| Assuming absent = unsupported | The absence means "not catalogued", not "impossible" |
