---
name: project-commands
description: "Project make targets, test commands, proxy rules, go doc protocol. Reference for all bash operations in this codebase."
---

# Project Commands

**Template — adapt make targets and commands to your project.**

**Target names vary per project.** Commands below are common examples. ALWAYS check actual `Makefile` for exact target names before running.

## Proxy

All `make` commands MUST run with proxy cleared:
```bash
HTTP_PROXY= HTTPS_PROXY= http_proxy= https_proxy= make <target>
```

## Build & Test

| Command (example) | Purpose | Notes |
|---------|---------|-------|
| `make build` | Build binary | |
| `make test-all` | Unit + integration tests | May be `make test` |
| `make test-unit` | Unit tests only | May be `make unit` |
| `make test-integration` | Integration tests only | May be `make integration` |

```bash
go test -v -race -count=1 -timeout 500ms ./path/to/package -run TestName
go test -v -race -count=1 -timeout 5s ./path/to/package --tags=integration -run TestName
```

## Code Generation

| Command | Purpose | Notes |
|---------|---------|-------|
| `make gen` | Proto + mocks + format | |
| `make generate` | Generate proto | |
| `make generate-config` | Generate config | Run if changed `values*.yaml` |
| `make mock` | Mock generation (mockery v2) | |
| `make fast-format` | Lint and format (fast) | If available in Makefile |

## Database

| Command | Purpose |
|---------|---------|
| `make migration` | Create migration file |
| `make migration-shards` | Create sharded migration file |
| `make datafix` | Create datafix file |
| `make migrate-up` | Apply migrations locally |
| `make db` | Drop and recreate local database |

## Run

```bash
HTTP_PROXY= HTTPS_PROXY= http_proxy= https_proxy= make run
```

## Verification Protocol

Build after every step. Full test-all at checkpoints defined in plan.
```bash
HTTP_PROXY= HTTPS_PROXY= http_proxy= https_proxy= make build
HTTP_PROXY= HTTPS_PROXY= http_proxy= https_proxy= make test-all
```

## External Package Documentation

ALWAYS use `go doc` for external package APIs. NEVER read vendor/ or GOMODCACHE files.
```bash
go doc example.com/pkg/name.TypeOrFunc
```
Only read files within the project directory. External packages → `go doc` only.
If `go doc` is insufficient → ask the user.

| Rationalization | Reality |
|----------------|---------|
| "Let me check the source in vendor/" | `go doc` shows the same API. vendor/ wastes tokens |
| "GOMODCACHE has the full source" | You don't need full source. You need the API contract |
| "go doc doesn't show implementation" | You need the interface, not the implementation. Ask user if stuck |
