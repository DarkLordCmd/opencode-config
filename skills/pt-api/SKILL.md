---
name: pt-api
description: Use when testing REST, GraphQL, or gRPC APIs — enumerating routes and schemas, building an authorization matrix, testing object-level and field-level access, mass assignment, rate limits, and token handling — including Russian requests (тестирование API, GraphQL, проверка авторизации в API). Use when a mobile app or SPA hides its real attack surface in the API layer.
version: 1.0.0
author: operator
tags: [offensive, api, graphql, grpc, rest, bola]
---

# API Testing

APIs fail differently than pages. There is no HTML to crawl, no form to submit — the contract is in a schema, a client bundle, or a mobile binary, and **authorization is decided per field, not per route**.

## Phase 1: Recover the contract

```bash
# Common spec locations
for p in swagger.json openapi.json v3/api-docs api-docs swagger/v1/swagger.json \
         .well-known/openapi.json graphql graphiql; do
  curl -s -o /dev/null -w "%{http_code} $p\n" "https://<host>/$p"
done

# From a SPA bundle or sourcemap
curl -s https://<host>/static/js/main.js.map -o tmp/main.js.map
grep -oE '"/api/[a-zA-Z0-9_/{}-]+"' tmp/main.js.map | sort -u

# From an APK / IPA
apktool d app.apk -o tmp/apk && grep -rhoE 'https?://[a-z0-9.-]+/[a-zA-Z0-9_/-]+' tmp/apk | sort -u
```

If the spec exists, import it into Burp/Postman, then diff **spec vs behaviour**: undocumented routes, unused params, and version drift (`/v1` still live while `/v2` is documented) are the highest-yield gaps.

Route discovery when there is no spec:

```bash
ffuf -u https://<host>/api/FUZZ -w api-endpoints.txt -mc all -fc 404 -t 30
ffuf -u https://<host>/api/v1/FUZZ -w api-endpoints.txt -mc all -fc 404 -t 30
```

Compare status codes carefully: a `401` on an existing route and `404` on a missing one is the map. A `405` reveals the route exists with a different verb.

## Phase 2: Authorization matrix

Build this in `notes\api-<host>.md` before exploiting anything:

| Route | anon | user_a | user_b's object | admin | Notes |
|---|---|---|---|---|---|
| GET /users/{id} | 401 | 200 self | **200 other** | 200 | BOLA |
| GET /users/{id}/settings | 401 | 200 | 403 | 200 | ok |
| PATCH /users/{id} | 401 | 200 self | 403 | 200 | ok |

Rules that catch real bugs:

- Test the **object-level** dimension (other user's id) separately from the **role** dimension (admin route as user).
- Test **every verb**, including `PATCH` and `DELETE`, and bulk/`batch` endpoints that skip per-object checks.
- Test **nested** and **filtered** access: `/orgs/{org}/members`, `?user_id=`, `?tenant=`, header-based tenancy.
- Test **field-level** authorization: can `user_a` set `role`, `is_admin`, `verified`, `balance`, `tenant_id` on their own update? (mass assignment)

```bash
# Minimal replay harness: token B, object id of A
curl -s -H "Authorization: Bearer $TOKEN_B" "https://<host>/api/v1/users/$ID_A" | jq .

# Mass assignment probe
curl -s -X PATCH -H "Authorization: Bearer $TOKEN_A" -H 'Content-Type: application/json' \
  -d '{"email":"a@x.tld","role":"admin","is_verified":true,"credit":99999}' \
  https://<host>/api/v1/users/me | jq .
```

## Phase 3: GraphQL

```graphql
# Introspection (often disabled in prod — try anyway, and try the bypass forms)
{ __schema { queryType { name } types { name kind fields { name args { name type { name } } } } } }

# Field-level authz: does the type expose admin-only fields to a normal token?
{ user(id: "1") { id email role passwordHash mfaSecret apiKeys { key } } }

# Hidden mutations
{ __schema { mutationType { fields { name } } } }
```

When introspection is disabled: field-name wordlists against suggestions (`Did you mean`), `__type(name:"User")` probes, and error-message inference.

Attack classes specific to GraphQL:

| Class | Technique |
|---|---|
| Batching / alias abuse | 1000 aliases in one query to bypass rate limits and 2FA attempt counters |
| Deep query DoS | Nested cycles — **only if RoE permits**, otherwise note as observation |
| Injection via arguments | Same payloads as REST but inside string args; watch for SQLi in filters |
| Directive abuse | `@include`, `@skip` to reach fields blocked client-side |
| Authorization by resolver | Read-only route checks auth, mutation resolver forgets |

```bash
# Send a raw query
curl -s https://<host>/graphql -H 'Content-Type: application/json' \
  -d '{"query":"{ __typename }"}'
```

## Phase 4: gRPC

```bash
grpcurl -plaintext <host>:<port> list                       # reflection enabled?
grpcurl -plaintext <host>:<port> describe <pkg.Service>     # message schema
grpcurl -plaintext -d '{"id":"1"}' <host>:<port> <pkg.Service>/GetUser
```

Without reflection you need the `.proto` from a leaked repo, mobile app, or a decompiled binary. Test authz the same way as REST: swap the bearer token, change the id, and check whether the server trusts client-supplied identity fields in the request message.

## Phase 5: Tokens and transport

- **JWT**: `alg:none`, weak HS256 secret, `kid` traversal, `jku`/`x5u` hijack. See `pt-web` for commands.
- **API keys**: in query string, in `Referer`, in logs, in mobile binary (`strings`, `apktool`), in JS bundle.
- **Token lifetime**: access token expiry enforced server-side? Refresh token rotation? Revocation on logout?
- **Rate limits**: per-token or per-IP? Bypass with rotating headers (`X-Forwarded-For`), IPv6 rotation, or batching.
- **Content-type confusion**: send JSON where XML expected, and vice versa; some frameworks dispatch differently per type and skip middleware.

## Phase 6: Versioning and deprecation

```bash
for v in v0 v1 v2 v3 beta internal; do
  curl -s -o /dev/null -w "$v %{http_code}\n" "https://<host>/api/$v/users/me"
done
```

Old versions keep old bugs. A `v1` that still accepts the legacy auth header is often the easiest way in.

## Output

`notes\api-<host>.md` holds the authorization matrix and each finding in the standard shape:

```markdown
### API-02 BOLA on GET /api/v1/documents/{id}
Severity: High
Precondition: tokens for user_a and user_b
Request:  curl -H "Authorization: Bearer $TOKEN_B" https://host/api/v1/documents/<doc_of_a>
Observed: 200 + document body
Expected: 403
```

## Common mistakes

| Mistake | Reality |
|---|---|
| Crawling only the UI | The SPA calls 3× more routes than it shows |
| Trusting the OpenAPI spec as complete | Undocumented and legacy routes are the bugs |
| Reporting 401 vs 404 noise as findings | It is a map, not a vulnerability |
| Testing only GET | State changes and BOLA live in PATCH/PUT/DELETE |
| Ignoring field-level authz | `role` in a profile update is privilege escalation |
| Skipping rate-limit analysis on auth endpoints | Unlimited OTP/credential attempts is a real finding |
| Not checking mobile clients | They ship the same API with different, older assumptions |
