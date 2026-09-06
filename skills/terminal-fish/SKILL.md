---
name: terminal-fish
description: Fish shell configuration, aliases, gRPC debugging, PostgreSQL CLI helpers, and dev workflow shortcuts for the Anachak platform.
---

# Terminal & Fish Shell Skill

The developer uses **fish shell** (`/opt/homebrew/bin/fish`) with a customized set of aliases, functions, and PostgreSQL helpers stored in `~/.config/fish/conf.d/`.

## Config Files

| File | Purpose |
|---|---|
| `~/.config/fish/conf.d/zzz_aliases.fish` | Navigation, git, system, gRPC, Rust/Cargo shortcuts |
| `~/.config/fish/conf.d/pg.fish` | PostgreSQL CLI toolkit with dot notation + JSON output |

## Quick Reference

| Topic | File |
|---|---|
| All aliases & shortcuts | [aliases.md](./aliases.md) |
| PostgreSQL helpers | [postgresql.md](./postgresql.md) |
| gRPC debugging | [grpc-debugging.md](./grpc-debugging.md) |
| Dev workflow patterns | [workflow-patterns.md](./workflow-patterns.md) |

## Most-Used Commands

### Daily Development

```fish
dg                          # cd ~/Documents/Github
cw                          # cargo watch -x run --no-restart (hot reload)
cc                          # cargo check
ct                          # cargo test
ship "feat: add billing"    # git add -A && commit && push origin main
kk                          # kill all dev server ports
```

### Database Inspection

```fish
pguse anachak_dev           # switch active database
pg auth_users               # dump table as JSON
pgc payments                # row count
pgs subscriptions           # schema + indexes
pgf auth_users admin email  # full-text search
pgq "SELECT * FROM..."      # raw SQL → JSON
```

### gRPC Debugging

```fish
list                                    # list all gRPC services
show AuthService                        # list RPCs for a service
call '{"identifier":"admin"}' auth.v1.AuthService/Login  # call with JSON
```

## Important Notes

- **Fish shell is the primary terminal** — all commands and aliases use fish syntax
- **`$PG_DB` universal variable** persists the active database across sessions (default: `anachak_dev`)
- **gRPC commands target `localhost:50050`** (the Anachak Rust backend default port)
- **`kk` kills ports**: 8080-8082, 50050-50054, 5173-5174, 3000-3002, 9090-9092
- **All `pg*` commands** pipe JSON output through `jq .` for pretty-printing
- **Dot notation** works on all pg commands: `pg anachak_dev.auth_users` or `pgc rust_grpc.payments`
