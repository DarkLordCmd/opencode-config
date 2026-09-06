---
name: backend-rust
description: Rust gRPC backend patterns, folder structure, module anatomy, and infrastructure wiring for the Anachak multi-tenant SaaS platform.
---

# Backend Rust Skill

Comprehensive guide for working with the **Anachak Rust** gRPC backend — a multi-tenant SaaS platform with 11 modules, 32 utility packages, and 90+ RPCs.

## Tech Stack

| Layer | Technology | Version |
|---|---|---|
| Language | Rust | 2021 edition |
| Transport | gRPC (Tonic) + gRPC-Web | tonic 0.12 |
| Database | PostgreSQL (SQLx) | sqlx 0.8 |
| Proto | Protocol Buffers v3 | Buf CLI v2 |
| Auth | JWT (jsonwebtoken 9) | Access + Refresh |
| Password | Argon2 (argon2 0.5) | PHC-format |
| Payments | Bakong/KHQR (EMV-compliant) | reqwest 0.12 |
| Metrics | Prometheus | prometheus 0.13 |
| WebSocket | tokio-tungstenite 0.24 | Notification broadcast |
| OTP | TOTP (totp-rs 5) | Google Authenticator |
| SMS | Plasgate | Cambodia gateway |
| Email | Resend | HTTP API |
| IDs | ULID (ulid 1) | Sortable, unique |
| Cache | In-memory / Redis (optional) | Feature-gated |
| Observability | tracing + optional OpenTelemetry | Feature-gated `otel` |
| Hot Reload | cargo watch | `cw` alias |

## Quick Reference

| Topic | File |
|---|---|
| Folder structure | [folder-structure.md](./folder-structure.md) |
| Module anatomy | [module-anatomy.md](./module-anatomy.md) |
| Infrastructure utils | [infrastructure.md](./infrastructure.md) |
| Interceptor/layer chain | [interceptors.md](./interceptors.md) |
| Database patterns | [database-patterns.md](./database-patterns.md) |
| Error handling | [error-handling.md](./error-handling.md) |
| Adding a new module | [new-module-checklist.md](./new-module-checklist.md) |
| Proto & Buf | [proto-and-buf.md](./proto-and-buf.md) |

## Module Summary

| Module | Files | Key Responsibility |
|---|---|---|
| **auth** | 4 (`auth.rs`, `auth_repo.rs`, `auth_service.rs`, `mod.rs`) | User accounts, JWT, 2FA, OAuth, sessions, audit |
| **company** | 4 | Multi-tenant company/branch/member management |
| **businesstype** | 4 | Industry presets (28 types), pricing tiers |
| **billing** | 4 | KHQR payments, Bakong polling, streaming |
| **coupon** | 4 | Coupon creation, validation, redemption tracking |
| **role** | 4 | RBAC role/permission management |
| **subscription** | 4 | Plan lifecycle, branch-scoped subscriptions |
| **notification** | 4 | In-app notification delivery |
| **currency** | 4 | Multi-currency exchange rates |
| **activity** | 4 | Audit activity logging |
| **admin** | 4 | Cross-cutting admin operations |

## Entrypoints

| File | Purpose |
|---|---|
| `main.rs` | Calls `internal::startup::run()` |
| `internal/startup/mod.rs` | Server bootstrap — env, DB, utils, gRPC server, HTTP, cron, shutdown |
| `internal/startup/proto.rs` | Proto module re-exports & file descriptor set |
| `internal/startup/events.rs` | Event handler registration |
| `internal/startup/cron_jobs.rs` | Cron job scheduling |
| `internal/startup/http_server.rs` | Side-channel HTTP (metrics + WebSocket) |
| `build.rs` | tonic-build proto compilation |

## Ports

| Port | Protocol | Purpose |
|---|---|---|
| `50050` | gRPC | Native gRPC + gRPC-Web |
| `9090` | HTTP | Prometheus metrics |
| `9091` | WebSocket | Real-time notification broadcast |

## Key Patterns

1. **Repository-Service** — Every module: `<module>.rs` (types) → `<module>_repo.rs` (data) → `<module>_service.rs` (business logic + gRPC)
2. **Arc-based dependency injection** — All shared services wrapped in `Arc<T>` and passed explicitly
3. **gRPC-first** — Proto is source of truth; gRPC-Web enabled for browser clients
4. **Tower layer chain** — 7 layers for cross-cutting concerns (recovery, timeout, logging, etc.)
5. **Tonic interceptor** — `AuthInterceptor` validates JWT + blacklist, injects user context into metadata
6. **Graceful shutdown** — `ShutdownCoordinator` manages ordered teardown of 5 components
7. **Forward-only SQL migrations** — Sequential `.sql` files in `migrations/`
8. **Event-driven side effects** — `EventBus` for decoupled reactions to domain events
9. **Feature flags** — PostgreSQL-backed with 60s in-memory refresh
10. **Unified error handling** — `AppError` enum → auto-converts to gRPC `Status` with `x-error-code` metadata
