---
name: pseudocode-writer
description: "Use when writing production pseudocode (L0 → L1 transition of pseudocode-pipeline). Produces Go files where signatures/types compile, bodies carry TODO: markers conveying intent at exact code locations."
---

# Pseudocode Writer

<IMPORTANT>

## Golden Rules

- **PW-1.** MUST invoke `duperpowers-go:go-writer` before editing any `.go` file. Go conventions apply to all real-Go parts.
- **PW-2.** Base is real Go — keep native keywords (`if`, `switch`, `case`, `default`, `return`, `for`, `defer`) and native operators. NO unicode operators (`→ ≠ ∧ ∨ ≤`). NO `:` + indent sugar (collides with Go's existing `:` meanings). If it does not look like Go it is wrong.
- **PW-3.** Two hole-markers only:
  - `// TODO: <intent>` — one-liner, body is a single sentence of intent
  - `/* TODO: <multi-line intent> */` — multi-line block when one TODO needs 2-5 lines of prose
  Optional short ID between `TODO:` and the intent groups related markers across files (e.g. `// TODO: F1 validate id`, `// TODO: F1 map to DTO`). ID = 1-5 alphanumeric chars, **uppercase by convention** (`F1`, `AUD`, `RX2`); no brackets, no punctuation around it.
- **PW-4.** Contracts (signatures, types, fields, interfaces, constants) MUST compile. Only bodies may hold `TODO:` markers.
- **PW-5.** Assignments are explicit: `res, err := repo.Get(ctx, id)`. No dangling expressions with implicit `err`. Use `_` for intentionally ignored returns.
- **PW-6.** `TODO:` descriptions are sentences a reviewer can act on — either intent that survives as final documentation ("validate id: reject empty, trim whitespace") or a question to be resolved on the way to L2 ("redact PII — which fields stay raw?"). Both forms valid; bare-ID markers (`// TODO: F1`) are not.
- **PW-7.** Body shape follows decidability, not novelty. Trivial bodies — write them out (a 2-line `return foo, nil` is denser than three lines of godoc + a zero-value stub). Reserve `TODO:` bodies for parts of the implementation you cannot decide right now.
- **PW-8.** On completion MUST invoke `duperpowers-go:verify` with target=L1. On FAIL, fix missing guarantees before declaring completion. Do NOT declare L1 without PASS.
- **PW-9.** Code-first, TODO-as-question. Before each `TODO:` apply the gate: *would a competent Go dev with this codebase open write this line right now?* Yes → write it. No → drop a `TODO:` and keep moving — `TODO:` IS the unblock mechanism, never pause to ask. Three guards:
  - **Read before TODO.** "Missing fact" = fact not derivable from the codebase or spec. If the fact lives in an unread file in this repo, read the file. Laziness ≠ missing fact.
  - **No fabrication.** Do not invent business rules, validation thresholds, error policies, or field semantics. Unspecified rule → `TODO:` mandatory; plausible-but-wrong code is harder to catch than a hole.
  - **Soft cap.** ≤2 inline `// TODO:` per new function. More = the layer is wrong; push the unknown up to a contract or write more code.

## Anti-patterns

| Rationalization | Reality |
|-----------------|---------|
| "I'll invent a concise notation — `err ≠ nil → wrap`" | No (PW-2). Every reputable corpus (Go proposals, Rust RFCs, Russ Cox essays) keeps real Go operators. Invented symbols rot — readers two years later cannot tell `→` from `⇒` from `↦`. |
| "Python-style `:` + indent reads cleaner inside Go bodies" | No (PW-2). `:` already means case-label, struct field, composite-literal key in Go. Adding a fifth meaning creates local ambiguity and breaks every Go tool. |
| "Tag every TODO with `[group-name]: ...`" | No brackets (PW-3). Optional short ID after `TODO:` is enough: `// TODO: F1 do the thing`. Grep matches `rg 'TODO: F1'`. |
| "Every function needs a pseudocode body for completeness" | No (PW-7). If you can write the body, write it; if you cannot, mark `TODO:`. Godoc + zero-value stub is anti-pattern — it is neither code nor a pinned question. |
| "TODO this if-branch — keeps the body short" | No (PW-9). `TODO:` is not a length-control tool. Decidable branches → write them. `TODO:` is reserved for unknowns and questions. |
| "Domain logic is complex — let me TODO the whole use-case body" | No (PW-9 + layer table). Domain core is decidable: `if`/`switch`/error-wrapping/field-copy is the densest signal there is. Write it. Save `TODO:` for adapters where SQL / proto / generated detail is genuinely deferred. |
| "I'll write `panic(\"TODO\")` so the test fails loudly at the unfilled site" | No (PW-3, PW-7). The two hole-markers are `// TODO:` and `/* TODO: */` — that is the entire alphabet. `panic` is real runtime behavior; using it as a placeholder corrupts the contract. Comment marker + zero-value `return` is enough. |
| "I'll put one `// TODO: implement this` at the top of the body and skip the rest" | No (PW-9). A function-top TODO is a blank-canvas hand-off — exactly what code-first replaces. Write the decidable structure (validation, error mapping, branching) and pin TODOs only at the genuinely undecided sites. |
| "`// TODO: F1` is enough — the ID groups it, intent is in the diff" | No (PW-6). Bare-ID markers carry zero information for the reviewer answering them and zero residual value once filled. Always: `// TODO: F1 <one-sentence intent or question>`. |
| "I haven't read the surrounding file but I'll TODO the unknown" | No (PW-9 read-before-TODO). "Missing fact" means *not derivable*. If the fact lives in a file in this repo, read the file first. |
| "I'll write a plausible validation rule and let the reviewer correct it" | No (PW-9 no-fabrication). Plausible-but-wrong code is harder to detect than a TODO. Unspecified rule → `TODO:` is mandatory. |

</IMPORTANT>

## North Star

This skill produces the **first pass** of a Go branch — for a Go-fluent reviewer who reads code faster than prose. Native Go is the signal. `TODO:` is reserved for what you cannot write without information you do not have, or a decision the reviewer must make.

Write the decidable code, pin the questions with `TODO:`, never pause. `TODO:` *is* the unblock mechanism — the reviewer batch-resolves markers on the way to L2 instead of filling a blank file.

### Code vs TODO by layer (defaults)

*This table assumes a hex / ports-and-adapters layout. Adapt labels to your project's vocabulary if it differs.*

| Layer | Default | TODO acceptable when |
|-------|---------|----------------------|
| Contracts — types, fields, interfaces, errors, constants | Real code (always) | — |
| Domain core — use-cases, services, validators, mappers | **Real code** — `if`/`switch`/error wrapping/field copy written out | a specific decision is genuinely deferred (policy unknown, redaction list TBD, validation rule not finalized) — pin to ONE site, not the whole body |
| Adapters in — grpc/http handlers, kafka consumers, schedulers, middleware | Real code for routing/decoding/error mapping | external spec, proto field, or idempotency strategy unknown |
| Adapters out — repos, kafka producers, grpc clients | Real signature **and call shape** (driver, cardinality, tx-scope, error mapping) | only the literal SQL string / proto field paths / generated-mock specifics |
| Infra / wiring — `cmd/`, providers, DI, config loading | Real code — it is just assembly | — |

Concurrency primitives are not their own layer. The loop, channel ops, cancellation paths follow PW-9 — write them as Go. Work inside a goroutine takes on the layer of what it does.

If you find yourself writing a `TODO:` inside a use-case branch, a mapper, or a validator — pin the unknown to ONE specific check, not the whole body. The layer is decidable; the question is local.

## Format — two shapes

**B is the default** — real Go body, `TODO:` only at genuine unknowns. **D** handles the rare `TODO:` that needs a multi-line question.

### B — Real Go body with `// TODO:` markers at unknowns (DEFAULT)

Write everything you can. Place a `// TODO: <id?> <intent>` at the exact site where you need information you do not have, or a decision from the reviewer.

```go
func (x *UserService) GetUser(ctx context.Context, id string) (*UserDTO, error) {
    if strings.TrimSpace(id) == "" {
        return nil, ErrInvalidID
    }

    u, err := x.repo.Get(ctx, id)
    if errors.Is(err, repository.ErrNotFound) {
        return nil, ErrUserNotFound
    }
    if err != nil {
        return nil, fmt.Errorf("GetUser(%s): %w", id, err)
    }

    return &UserDTO{
        ID:    u.ID,
        Name:  u.Name,
        Email: u.Email,
        // TODO: F1 redact PII per security policy — which fields stay raw, which masked?
    }, nil
}
```

Decidable code is written; one `TODO: F1` pins the genuine unknown.

### D — Multi-line `/* TODO: ... */` block for a multi-line question

Use when a single `TODO:` needs 2-5 lines of prose because the question itself has internal structure (a matrix, a numbered list, a multi-dimensional decision space). One block per function, maximum two.

```go
func (x *UserService) DeleteUser(ctx context.Context, id string, hard bool) error {
    /* TODO: F2 permission policy — confirm matrix
       - !admin && hard          -> ErrForbidden ?
       - !admin && !hard && own  -> allow ?
       - admin                   -> allow both ?
    */

    if hard {
        if err := x.repo.HardDelete(ctx, id); err != nil {
            return fmt.Errorf("HardDelete(%s): %w", id, err)
        }
        if err := x.events.Publish(ctx, &UserPurgedEvent{
            ID: id,
            // TODO: F2 confirm payload — tenant_id? actor? timestamps?
        }); err != nil {
            return fmt.Errorf("publish UserPurged: %w", err)
        }
        return nil
    }

    if err := x.repo.SoftDelete(ctx, id, time.Now()); err != nil {
        return fmt.Errorf("SoftDelete(%s): %w", id, err)
    }
    if err := x.events.Publish(ctx, &UserDeletedEvent{
        ID: id,
        // TODO: F2 confirm payload — tenant_id? actor? timestamps?
    }); err != nil {
        return fmt.Errorf("publish UserDeleted: %w", err)
    }
    return nil
}
```

Branch structure, error wrapping, and `Publish` invocations are decidable — written. The two open questions (permission matrix + event payload shape) pin at the exact sites.

## Modifying existing code — write the new code in place

When a diff touches existing code, **write the new code in place**. Use `// TODO: <id?> <intent>` only at sites where the change itself is undecided (policy, payload shape, ordering question). A change with a known shape — capture old state, wrap an error, append to an outbox table — is decidable; write it as Go.

```go
func (x *UserService) UpdateUser(ctx context.Context, u *User) error {
    if err := u.Validate(); err != nil {
        return err
    }

    oldState, err := x.repo.Get(ctx, u.ID)
    if err != nil {
        // TODO: AUD audit-fetch failure — retryable, or hard-fail with ErrInternal?
        return fmt.Errorf("UpdateUser(%s): audit fetch: %w", u.ID, err)
    }

    if err := x.repo.Save(ctx, u); err != nil {
        return fmt.Errorf("UpdateUser(%s): save: %w", u.ID, err)
    }

    x.audit.Emit(ctx, AuditEvent{
        Op:     "update",
        Before: oldState,
        After:  u,
        // TODO: AUD confirm event shape — full snapshots or just changed fields? + topic
    })
    return nil
}
```

Two `TODO:` markers, both genuine policy questions; everything else is real Go. The file compiles (`oldState` is referenced in `audit.Emit`).

## Relationship to Other Skills

- `duperpowers-go:pseudocode-writer-test` — next skill in the pipeline (L1 → L1.5). Same `TODO:` format applies inside test bodies.
- `duperpowers-go:go-writer-test` — not loaded here (production code only).

<IMPORTANT>

## Anchor

- **PW-9.** Code-first, TODO-as-question — write what you can; `TODO:` for unknowns; never pause to ask. Read the file before TODOing; never fabricate.
- **PW-2.** Real Go: native keywords and operators. No unicode, no `:`+indent.
- **PW-4.** Contracts (signatures, types, fields, interfaces) MUST compile; only bodies hold `TODO:`.
- **PW-7.** Body shape follows decidability — write what you can decide; `TODO:` only what you cannot.
- **PW-3.** Hole-markers only: `// TODO:` one-liner or `/* TODO: */` block; uppercase short ID, no brackets.
- **PW-1.** Load `go-writer` before editing `.go`.
- **PW-8.** On completion invoke `verify L1`. FAIL → fix, not declare.

</IMPORTANT>
