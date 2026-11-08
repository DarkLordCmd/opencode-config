---
name: rea-app
description: Use when reversing a packaged application — Android APK/AAB or DEX, .NET assembly, JVM jar/class, Electron app, React Native or Flutter bundle, HarmonyOS package — to read its code, resources, manifest, network logic or protections — including Russian requests (разобрать APK, декомпилировать .NET, распаковать Electron, реверс приложения, обойти certificate pinning). Catalogue-driven.
version: 1.0.0
author: operator
tags: [reverse-engineering, android, dotnet, jvm, electron, apk, decompiler]
---

# Packaged applications

306 app-targeted entries across Android (77), .NET (6), JVM (7), JS/Electron (9) and dynamic analysis
(26). Pick the runtime first — the toolchain is different for every one.

```bash
python3 scripts/catalog.py --target app --category android
python3 scripts/catalog.py --target app --category dotnet --json
```

## Android / DEX

| Tool | URL | Purpose |
|---|---|---|
| APKLab | https://github.com/APKLab/APKLab | VS Code workbench around apktool, jadx, smali-lsp, uber-apk-signer |
| APKEditor | https://github.com/REAndroid/APKEditor | decode resources/DEX to JSON/smali and rebuild |
| Androguard | https://github.com/androguard/androguard | APK/DEX metadata, bytecode and reference analysis from Python |
| APKiD | https://github.com/rednaga/APKiD | identify packers, protectors, obfuscators, anti-debug |
| Android Security Toolkit | https://github.com/abhirampatel/android-security-toolkit | fast triage: manifest flags, strings, native libs |
| Android Unpinner | https://github.com/mitmproxy/android-unpinner | remove certificate pinning from an APK you are authorized to test |
| Andromeda | https://github.com/secrary/Andromeda | CLI first-pass RE of APKs |
| Frida | https://github.com/frida/frida | runtime instrumentation once static analysis stalls |

Flow: `APKiD` (what protects it) → `APKEditor`/jadx (code and resources) → `Androguard` (facts in bulk)
→ `Frida` (runtime truth). Unpinning is a testing step against your own or authorized builds only.

HarmonyOS: `abc-decompiler` and `ABCDE` handle Ark bytecode (`.abc`).
Flutter: `AOTopsy` recovers metadata and structure from `libapp.so` without symbols.

## .NET (Unity Mono, XNA, plain assemblies)

| Tool | URL | Purpose |
|---|---|---|
| dnSpyEx | https://github.com/dnSpyEx/dnSpy | debug and edit assemblies without source |
| ILSpy | https://github.com/icsharpcode/ILSpy | browse, decompile, export a whole project |
| de4dot | https://github.com/de4dot/de4dot | deobfuscate and unpack protected assemblies |
| AsmResolver | https://github.com/Washi1337/AsmResolver | library for programmatic PE/.NET rewriting |
| CodemerxDecompile | https://github.com/codemerx/CodemerxDecompile | cross-platform desktop decompiler |
| ilspy-cli | https://github.com/akiselev/ilspy-cli | targeted decompilation from the command line, usable by agents |

Order: `de4dot` first if obfuscated, then ILSpy/dnSpyEx; script the boring parts with AsmResolver.

## JVM

`Vineflower` (https://github.com/Vineflower/vineflower) — modern Fernflower-derived decompiler;
`Recaf` (https://github.com/Col-E/Recaf) — edit and decompile in one workspace;
`Bytecode Viewer` (https://github.com/Konloch/bytecode-viewer) — many decompilers side by side;
`Soot` (https://github.com/soot-oss/soot) — programmatic analysis and transformation;
`slicer` (https://github.com/katana-project/slicer) — browser-based disassembly.

## Electron / JS-packaged apps

`@electron/asar` for `app.asar`; `bun-demincer` for Bun-compiled executables;
`React Native Decompiler` for `index.android.bundle`; `wxapkg` for WeChat mini-programs.
After unpacking, continue with `rea-website`.

## Playbook

1. **Identify runtime and protection** (APKiD, file headers, `strings`, loader names).
2. **Prefer the managed layer**: DEX/IL/bytecode first, native last.
3. **Extract resources and manifest** — permissions, exported components, endpoints, keys.
4. **Go dynamic** when the logic is split, obfuscated or resolved at runtime (Frida, debugger).
5. **Record** version, tool versions, and what was actually executed vs read.

## Common mistakes

| Mistake | Reality |
|---|---|
| jadx on a packed APK | The real DEX is unpacked at runtime; get it dynamically first |
| Reading IL2CPP as if it were C# | Names and types are reconstructed, not original |
| Unpinning without authorization | You are modifying someone's app for interception |
| Ignoring the manifest | Exported components and `usesCleartextTraffic` are often the finding |
