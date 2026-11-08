---
name: rea-game
description: Use when reverse engineering a game — extracting Unity/Unreal assets, recovering IL2CPP or Mono assemblies, decompiling or recompiling engine code, porting or matching-decompiling a title, or building mods and patches — including Russian requests (реверс игры, распаковка ресурсов, Unity, IL2CPP, декомпиляция игры, моды). Catalogue-driven.
version: 1.0.0
author: operator
tags: [reverse-engineering, game, unity, il2cpp, unreal, assets, modding]
---

# Game reverse engineering

Goal: get from a shipped game to its assets, its code and its behaviour. The catalogue holds 377
game-targeted entries — 79 analysis tools and **222 reconstruction cases**, which is the most valuable
part: someone has already mapped your engine.

Catalogue slice: `--target game`.

## Identify the engine first

Everything downstream depends on this. Signs: `UnityPlayer.dll` / `globalgamemanagers` (Unity),
`*.pak` + `Engine/` (Unreal), `*.bsp` + `gameinfo.txt` (Source), `data/*.bin` + emulator (retro).

```bash
python3 scripts/catalog.py --target game --category game-analysis
python3 scripts/catalog.py "il2cpp" --target game --json
```

## Core tooling

| Tool | URL | Purpose |
|---|---|---|
| AssetRipper | https://github.com/AssetRipper/AssetRipper | Unity assets → Unity project |
| AssetStudio | https://github.com/Perfare/AssetStudio | Unity 3.4–2022.1 asset and bundle explorer |
| Cpp2IL | https://github.com/SamboyCoding/Cpp2IL | recover managed view from IL2CPP builds |
| BepInEx | https://github.com/BepInEx/BepInEx | plugin/patch framework (Mono, IL2CPP, .NET) |
| BSPSource | https://github.com/ata4/bspsrc | Source `.bsp` → `.vmf` |
| Cheat Engine | https://github.com/cheat-engine/cheat-engine | memory scan, debug, disassemble in a live game |
| asm-differ | https://github.com/simonlindholm/asm-differ | diff original vs rebuilt assembly for matching decomp |
| Aspyr Archive Tool | https://github.com/Dhamp1r/AspyrArchiveTool | OBB archive unpack/rebuild for known ports |

Archive formats are title-specific: search the catalogue by game name before writing a parser
(`python3 scripts/catalog.py "<title>" --target game`). The 222 reconstruction cases usually document
the format, the offsets and the toolchain the community settled on.

## Playbook

1. **Identify engine, version and platform** (PC/console/mobile changes everything).
2. **Look for a matching-decomp or reconstruction case** for this title — it saves weeks.
3. **Extract assets** (AssetRipper/AssetStudio for Unity, title tools otherwise).
4. **Recover code**: Mono → dnSpy/ILSpy (see `rea-app`); IL2CPP → Cpp2IL then the same .NET tools.
5. **Observe runtime** with a debugger or Cheat Engine when static reading stalls.
6. **For matching decompilation**: rebuild, byte-compare, iterate with `asm-differ`. "Looks correct" is
   not the bar — matching output is.
7. **Record** engine, version, tool versions, and which case the approach came from.

## Legal and scope

Reverse engineering a game is legal in many jurisdictions for interoperability, but distributing
extracted assets or bypassed protection is a different matter. Keep extracted assets inside the
engagement folder, do not publish them, and state ownership in the report.

## Common mistakes

| Mistake | Reality |
|---|---|
| Writing a parser before searching the catalogue | The format is usually already documented |
| Assuming Unity version | AssetStudio support stops at 2022.1; newer titles need current tools |
| Treating IL2CPP output as source | Cpp2IL gives a reconstruction; names and types are partly inferred |
| Matching decomp judged by eye | Byte comparison is the only pass criterion |
