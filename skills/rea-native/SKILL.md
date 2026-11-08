---
name: rea-native
description: Use when working with a compiled binary — ELF, PE, Mach-O or WebAssembly — for disassembly, decompilation, symbolic execution, vulnerability hunting, function matching between versions, or dynamic instrumentation of native code — including Russian requests (дизассемблировать, декомпилировать бинарник, анализ ELF/PE, диф бинарников, символьное исполнение). Catalogue-driven.
version: 1.0.0
author: operator
tags: [reverse-engineering, binary, disassembler, decompiler, symbolic-execution, diffing]
---

# Native binaries

472 binary-targeted entries: 141 native-analysis, 66 dynamic-analysis, 32 libraries, 8 diffing tools.
This is the deepest part of the catalogue and the easiest to drown in — pick by task, not by hype.

```bash
python3 scripts/catalog.py --target binary --category native-analysis
python3 scripts/catalog.py "decompiler" --target binary --json
python3 scripts/catalog.py --category binary-diffing --target binary
```

## Static: open it

| Tool | URL | Note |
|---|---|---|
| IDA (Hex-Rays) | https://hex-rays.com/ | commercial; best decompiler for many architectures |
| Ghidra | https://github.com/NationalSecurityAgency/ghidra | free, scriptable, strong headless mode |
| Binary Ninja | https://binary.ninja/ | commercial, excellent API (C++/Python/Rust) |
| angr / angr-management | https://github.com/angr/angr | symbolic execution and CFG recovery |
| Binary Refinery | https://github.com/binref/refinery | composable CLI units for byte transforms |
| Capstone | https://github.com/capstone-engine/capstone | disassembly library for custom tooling |
| 010 Editor | https://www.sweetscape.com/010editor/ | binary templates for file formats |
| BinAbsInspector | https://github.com/KeenSecurityLab/BinAbsInspector | Ghidra-based static vulnerability scanner |

For headless automation prefer Ghidra scripts or the Binary Ninja API; do not drive a GUI when the
task is "classify 400 binaries".

## Dynamic: run it

`Frida` (https://github.com/frida/frida) — instrumentation and hooks;
`DRAKVUF` (https://github.com/tklengyel/drakvuf) — agentless, hypervisor-based;
`CAPEv2` (https://github.com/kevoreilly/CAPEv2) — sandbox with API traces;
`decomp2dbg` (https://github.com/mahaloz/decomp2dbg) — decompiler names inside the debugger;
`deREferencing` (https://github.com/danigargu/deREferencing) — readable register/stack dereferencing.

## Diffing

`BinDiff` + `BinExport` (https://github.com/google/bindiff) — matched functions across versions;
`Diaphora` (https://github.com/joxeankoret/diaphora) — IDA-based, transfers names and types;
`ghidriff` (https://github.com/clearbluejar/ghidriff) — headless Ghidra diffing;
`Karta` (https://github.com/CheckPointSW/Karta) — open-source library matching;
`Pigaios` (https://github.com/joxeankoret/pigaios) — source-to-binary matching.

Diffing answers "what changed in the patch" faster than reading either binary.

## Playbook

1. **Triage**: file type, arch, packer, imports, strings, entropy.
2. **Name the target**: is this a patch diff, a crash, a protocol, or a licence check?
3. **Choose a surface**: managed layer if present (`rea-app`), else static decompilation.
4. **Instrument** rather than read when control flow is data-driven.
5. **Confirm with runtime**: static claims about behaviour are hypotheses.
6. **Record** binary hash, tool version, base address, and the exact commands used.

## Evidence rules

- A decompiler's output is a reconstruction. Never quote it as source.
- "Reachable" from static analysis is not "exploitable" — state which one you proved.
- Keep hashes of every binary analysed (evidence manifest, see `pt-report`).

## Common mistakes

| Mistake | Reality |
|---|---|
| Starting in IDA on a 50 MB binary | Triage first; most of it is library code |
| Symbolic execution on everything | It explodes; use it on one function with a question |
| Diffing without matched symbols | Bindiff/Diaphora need the export step (BinExport) |
| Trusting one decompiler | Cross-check the tricky function in a second one |
