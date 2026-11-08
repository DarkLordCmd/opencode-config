---
name: pt-recon
description: Use when mapping a target's external footprint before exploitation — subdomain enumeration, DNS and certificate transparency, ASN and netblock discovery, technology fingerprinting, endpoint and secret harvesting from JS or public sources — including Russian requests (разведка, сбор информации о цели, поиск поддоменов, OSINT). Assumes scope is already written.
version: 1.0.0
author: operator
tags: [offensive, recon, osint, subdomains, fingerprint]
---

# Reconnaissance

Passive first, active second, everything recorded. The goal is not "a big list" — it is an **attack surface map with owners and technologies attached**.

## Order of operations

1. **Passive** — no packets to the target: ASN, certificates, archives, code hosting, search engines.
2. **Attribution** — which hosts actually belong to the client vs a CDN, SaaS, or unrelated owner. Wrong attribution = out-of-scope testing.
3. **Active** — DNS brute, vhost discovery, HTTP probing, port hints.
4. **Harvest** — endpoints, parameters, emails, secrets from JS and public repos.

## Passive

```bash
# ASN and netblocks
whois -h whois.radb.net -- '-i origin AS<num>' | grep -E '^route'
curl -s "https://api.bgpview.io/asn/<num>/prefixes" | jq -r '.data.ipv4_prefixes[].prefix'

# Certificate transparency — subdomains without touching the target
curl -s "https://crt.sh/?q=%25.<domain>&output=json" | jq -r '.[].name_value' | sort -u
curl -s "https://otx.alienvault.com/api/v1/indicators/domain/<domain>/passive_dns" \
  | jq -r '.passive_dns[].hostname' | sort -u

# Archives and historical endpoints
curl -s "http://web.archive.org/cdx/search/cdx?url=<domain>/*&output=txt&collapse=urlkey&fl=original" \
  | sed 's/?.*//' | sort -u > scans/dns/wayback-<domain>.txt
```

Search-engine and code-host queries to run manually (record results, do not paste raw dumps):

- `site:<domain> -www` · `site:<domain> ext:php|aspx|jsp` · `site:pastebin.com "<domain>"`
- GitHub: `"<domain>" password`, `"<domain>" api_key`, org repos, Actions secrets exposure
- Shodan / Censys / FOFA: `ssl:"<domain>"`, `org:"<client>"`, `http.favicon.hash:<mmh3>`
- Job posts and docs for technology stack (cheapest tech fingerprint that exists)

## Attribution check

For every candidate host, before adding to the target list:

```bash
dig +short <host>            # CNAME to *.cloudfront.net / *.azurefd.net => edge, not origin
curl -sI https://<host> | grep -i -E 'server|via|x-cache|x-served-by'
whois <ip> | grep -i -E 'orgname|netname|descr'
```

Rules:

- CDN/SaaS edge = **not in scope** unless explicitly listed.
- Shared hosting IP = test the vhost, not the neighbour sites.
- Cloud IP ranges: `curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | jq ...` — never scan the provider.

## Active

```bash
# Subdomain brute (two wordlists: short high-signal + long)
ffuf -u https://FUZZ.<domain> -w subdomains-top1million-5000.txt -mc 200,301,302,401,403 -t 40 \
  -o scans/dns/ffuf-<domain>.json -of json

# DNS brute with wildcard filtering
dnsx -d <domain> -w subs.txt -wd <domain> -resp -silent > scans/dns/dnsx-<domain>.txt

# Zone transfer attempt (still happens)
dig axfr @<ns> <domain>

# Vhost discovery on a known IP
ffuf -u http://<ip> -H "Host: FUZZ.<domain>" -w subs.txt -fs <default-size>

# HTTP probe: status, title, tech, cert SANs, favicon hash
httpx -l hosts.txt -sc -title -tech-detect -favicon -jarm -json \
  -o scans/http/httpx-<domain>.jsonl
```

Wildcard DNS handling: resolve a random label first (`dig +short "$(openssl rand -hex 8).<domain>"`). If it answers, every brute hit is noise — filter by content length and body hash.

## Harvest

```bash
# Endpoints and params from JS bundles
cat js-urls.txt | xargs -P 10 -I{} curl -s {} -o tmp/js/$(echo {} | md5sum | cut -c1-8).js
grep -ohE '"/[a-zA-Z0-9_./-]{3,60}"' tmp/js/*.js | tr -d '"' | sort -u
grep -ohE '(api[_-]?key|secret|token|password)["'\'']?\s*[:=]\s*["'\''][^"'\'']{8,}' tmp/js/*.js

# robots, sitemap, security.txt, sourcemaps
for p in robots.txt sitemap.xml .well-known/security.txt; do curl -s "https://<host>/$p"; done
curl -s https://<host>/static/js/main.js.map -o tmp/main.js.map   # sourcemap => original source

# Email/username format for later spraying
# first.last@, flast@, firstl@ — infer from public press releases, verify against SMTP RCPT only if in scope
```

Email format enumeration is legitimate; validating addresses by SMTP probing is a different technique with its own noise footprint — only if RoE allows.

## Output discipline

```text
scans\dns\      crtsh-<domain>.txt  dnsx-*.txt  ffuf-*.json  wayback-*.txt
scans\http\     httpx-*.jsonl  tech-<host>.md
notes\recon.md  one table: host | ip | owner | tech | ports known | in scope?
```

`notes\recon.md` is the artifact that matters. A host counts only when you can state its owner and whether it is in scope.

## Tech fingerprinting quick table

| Signal | Meaning | Next step |
|---|---|---|
| `X-Powered-By: PHP/7.x` | PHP stack | version → CVE map, `.php` fuzz |
| `x-amz-*` headers on direct host | S3 origin / misconfigured bucket | bucket enumeration, ACL check |
| `X-Generator: WordPress` | CMS | plugin/theme enum, `wp-json` |
| Next.js build id in `/_next/static` | Next.js | `/_next/data/<buildId>`, RSC endpoints |
| Swagger/OpenAPI at `/swagger.json` | API spec | full route map, auth matrix |
| Jenkins/Grafana headers | internal tool exposed | default creds, unauth endpoints |
| `.git/HEAD` returns 200 | source disclosure | dump repo, mine secrets |

## OPSEC

- Passive phases leave no footprint — do them fully first.
- Active DNS brute against client DNS may trigger rate limits; use `-t 40`, not 500.
- Never resolve target domains through a resolver you do not control when the client asked for source-IP hygiene.
- Timestamp every scan start/stop in `notes\timeline.md`.

## Common mistakes

| Mistake | Reality |
|---|---|
| Adding every crt.sh entry to the target list | Most are CDN, dead, or another tenant |
| Ignoring wildcard DNS | Hundreds of false subdomains, hours lost |
| Skipping the owner check | You may be scanning a third party |
| Treating JS as read-only | Best source of hidden endpoints and leaked keys |
| Recon with no written output | Findings evaporate; report gets thin |
| Forgetting IPv6 and non-HTTP services | Modern estates expose both |
