---
name: rea-website
description: Use when inspecting or reconstructing a website's client side — deobfuscating minified JavaScript, unpacking webpack/browserify bundles, recovering API endpoints and routes from a SPA, reading browser extensions, or rebuilding behaviour from a captured session — including Russian requests (деобфускация JS, разбор бандла, вытащить API из сайта, разобрать расширение). Catalogue-driven.
version: 1.0.0
author: operator
tags: [reverse-engineering, web, javascript, deobfuscation, spa]
---

# Website / client-side JavaScript

Goal: turn a shipped, minified, possibly obfuscated client into readable logic and a concrete list of
endpoints, parameters and checks — the same things a pentest needs (see `pt-web`, `pt-api`).

Catalogue slice: `--target website` (90 entries: 42 web-analysis, 5 js/electron, 9 reconstruction cases).

## Capture first

An unmodified bundle beats a guessed one. Capture from a live session:

```bash
# everything the page loaded, with responses
python3 scripts/catalog.py "capture session" --target website
```

Relevant starters from the catalogue:

| Tool | For |
|---|---|
| breakinggood | screenshot + cleaned DOM + computed styles + XHR/fetch responses in one run |
| Browser Reverse Engineering Toolkit | persistent Chromium session, offline archive |
| Dembrandt | computed styles via Playwright — design tokens and layout facts |
| DevLens Ultra | component structure from the live DOM |
| CRX Viewer | read a packaged browser extension without installing it |

## Unpack and deobfuscate

| Tool | URL | When |
|---|---|---|
| webcrack | https://github.com/j4k0xb/webcrack | webpack/browserify bundles, common obfuscators |
| debundle | https://github.com/1egoman/debundle | split a bundle back into a file tree |
| de4js | https://github.com/lelinhtinh/de4js | browser-based unpacker, offline PWA |
| decode-js | https://github.com/echo094/decode-js | Babel AST deobfuscation |
| humanify | https://github.com/jehna/humanify | LLM renaming of minified identifiers (scope-aware AST) |
| React-Decode | https://github.com/alexandra-seredkina/React-Decode | compiled React → readable output, inferred API/routes |
| @electron/asar | https://github.com/electron/asar | Electron `app.asar` listing and extraction |

**Order:** unpack → deobfuscate → rename → read. Renaming before unpacking wastes the run.

## Playbook

1. **Capture** the page with a real session (Playwright), saving all JS responses and XHR/fetch bodies.
2. **Unpack** with webcrack/debundle; keep the original alongside the result.
3. **Deobfuscate** string arrays and control-flow flattening (de4js / decode-js).
4. **Rename** identifiers only when the structure is understood; `humanify` helps reading, not analysis.
5. **Extract** endpoints, parameters, feature flags, auth headers, and the client-side checks that
   protect paid features.
6. **Verify against the network**, not against the code: a check in JS that the server does not repeat
   is a client-side gate only — say exactly that in the report.
7. **Write the map** into `notes/web-<host>.md`: route, method, params, auth, client-side gate.

## What the catalogue cannot tell you

- Whether the server enforces what the client checks. That requires a request, not a bundle.
- Whether an obfuscator is fully reversible. Read each tool's README for supported patterns.

## Common mistakes

| Mistake | Reality |
|---|---|
| Reading minified code without unpacking | Two hours for what `webcrack` gives in seconds |
| Trusting a client-side gate | It is a hint; the server decides |
| Reporting an endpoint from a string literal | Constants rot; confirm with a request or a captured response |
| Ignoring source maps | A shipped `.map` ends the task immediately — check before deobfuscating |
