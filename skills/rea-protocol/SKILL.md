---
name: rea-protocol
description: Use when reversing a wire format or device protocol — decoding captured traffic, inferring an undocumented binary protocol, protobuf without a schema, BLE/GATT, CAN/automotive, or a custom TCP/UDP exchange — including Russian requests (разбор протокола, реверс трафика, неизвестный формат, BLE, CAN, protobuf без схемы). Catalogue-driven.
version: 1.0.0
author: operator
tags: [reverse-engineering, protocol, traffic, protobuf, ble, can]
---

# Wire protocols

140 protocol-targeted entries (54 in protocol-analysis). Two situations: you have captures and no
schema, or you have a client and no server documentation. The catalogue covers both, and the cases
often document method IDs and field layouts for well-known products.

```bash
python3 scripts/catalog.py --target protocol
python3 scripts/catalog.py "protobuf" --target protocol --json
```

## Decoding without a schema

| Tool | URL | Purpose |
|---|---|---|
| Blackbox Protobuf | https://github.com/nccgroup/blackboxprotobuf | decode/re-encode protobuf messages without `.proto` |
| AALpy | https://github.com/DES-Lab/AALpy | automata learning — infer state machines from observed I/O |
| BtleJuice | https://github.com/DigitalSecurity/btlejuice | intercept BLE GATT operations between devices |
| Cabana | https://github.com/deanlee/openpilot-cabana | CAN/CAN FD analysis for unknown signals |
| Automated CAN Payload RE | https://github.com/brent-stone/CAN_Reverse_Engineering | scripts that automate CAN payload inference |
| Apple Continuity Toolkit | https://github.com/seemoo-lab/apple-continuity-tools | Apple wireless service helpers |

Standard capture layer (not catalogue-specific, but needed): `tcpdump`/`Wireshark` for packets,
`mitmproxy` for TLS with a trusted CA, `btmon`/`hcitool` for BLE on Linux.

## Playbook

1. **Capture clean**: one action per capture, timestamps, both directions, client and server versions.
2. **Classify the shape**: length-prefixed binary, protobuf, JSON, CBOR, fixed-size struct, text.
3. **Find the boundaries**: repeated actions with one variable changed reveal field offsets and types.
4. **Build a decoder**: pcap → parser → named fields; keep the parser in the engagement folder.
5. **Confirm by replay**: send a mutated message and observe the effect. Replay is the proof.
6. **Document**: message table (offset, size, type, meaning, confidence), plus what remains unknown.

State machines are worth the extra step: `AALpy` infers them from traces and turns "unclear" into a
diagram the client can read.

## Interaction with the rest of the pack

- Client-side handler found in JS/APK → `rea-website` / `rea-app`.
- Protocol inside firmware → `rea-firmware`.
- The service you are speaking to belongs to a pentest → `pt-api`, and keep to its scope rules.

## Evidence rules

- A field hypothesis is a hypothesis. Mark confidence per field, not per document.
- Keep the raw capture (hashed) — a decoder without the pcap is unreproducible.
- If replay could alter production state, do it once and say so; prefer a staging endpoint.

## Common mistakes

| Mistake | Reality |
|---|---|
| Decoding protobuf by eye | Blackbox Protobuf does it in seconds and gives you the wire types |
| Mixing two actions in one capture | You cannot attribute a delta to a cause |
| Treating TLS as unbreakable | With a trusted CA and a client you control, `mitmproxy` sees everything in plaintext |
| Skipping the state machine | Many "unknown bytes" are session counters, not payload |
