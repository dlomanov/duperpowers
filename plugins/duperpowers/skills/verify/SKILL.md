---
name: verify
description: "Verify code after changes - build, then run minimal sufficient tests"
user_invocable: false
---

# Verify

Use after writing or modifying code to ensure nothing broke.

## Execution

### 1. Build (always first)
```bash
HTTP_PROXY= HTTPS_PROXY= http_proxy= https_proxy= make build
```
Stop on failure.

### 2. Tests - choose scope by change type

**Single test** - specific function, exact test known:
```bash
go test -v -race -count=1 -timeout 500ms ./path --tags={unit|integration} -run TestName
```

**Unit only** - business logic, utilities, internal packages:
```bash
go test -v -race -count=1 ./... --tags=unit
```

**Integration only** - adapters, database, external integrations:
```bash
go test -v -race -count=1 -timeout 5s ./... --tags=integration
```

**All tests** - large refactoring, cross-cutting, or uncertain:
```bash
HTTP_PROXY= HTTPS_PROXY= http_proxy= https_proxy= make test-all
```

## Decision Rules

- Choose minimal scope that covers your changes
- When uncertain, choose broader scope
- Never skip tests after code modifications
