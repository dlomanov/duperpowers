---
name: pseudocode-writer
description: "Use when writing production pseudocode (L0 → L1 transition of pseudocode-pipeline). Produces Go files where signatures/types compile, bodies carry TODO: markers conveying intent at exact code locations."
---

# Pseudocode Writer

<IMPORTANT>

## Golden Rules

- **PW-1.** MUST invoke `duperpowers-go:go-writer` before editing any `.go` file. Go conventions apply to all real-Go parts.
- **PW-2.** Base is real Go — keep native keywords (`if`, `switch`, `case`, `default`, `return`, `for`, `defer`), native operators (`!=`, `&&`, `||`, `!`, `==`, `<`, `<=`, etc.), and real assignments. NO unicode operators (`→ ≠ ∧ ∨ ≤`). NO `:` + indent sugar (collides with Go's existing `:` meanings). If it does not look like Go it is wrong.
- **PW-3.** Two hole-markers only:
  - `// TODO: <intent>` — one-liner, body is a single sentence of intent
  - `/* TODO: <multi-line intent> */` — multi-line block when one TODO needs 2-5 lines of prose
  Optional short ID between `TODO:` and the intent groups related markers across files (e.g. `// TODO: F1 validate id`, `// TODO: F1 map to DTO`). ID = 1-5 alphanumeric chars; no brackets, no punctuation around it.
- **PW-4.** Contracts (signatures, types, fields, interfaces, constants) MUST compile. Only bodies may hold TODO markers.
- **PW-5.** Assignments are explicit: `res, err := repo.Get(ctx, id)`. No dangling expressions with implicit `err`. Use `_` for intentionally ignored returns.
- **PW-6.** TODO descriptions are sentences that would survive as final comments after implementation. "Validate id: reject empty, trim whitespace" > "validate id". (Per McConnell PDL — the pseudocode step survives as documentation.)
- **PW-7.** Body shape follows decidability, not novelty. Trivial bodies — write them out (a 2-line `return foo, nil` is denser than three lines of godoc + a zero-value stub). Reserve `TODO:` bodies for parts of the implementation you cannot decide right now.
- **PW-8.** On completion MUST invoke `duperpowers-go:verify` with target=L1. On FAIL, fix missing guarantees before declaring completion. Do NOT declare L1 without PASS.
- **PW-9.** Code-first, TODO-as-question. Before each `TODO:` ask: *can I write this line as real Go right now?* Yes → write it (even imperfect Go beats prose). No (missing fact, undecided trade-off, question for the reviewer) → leave a `TODO:` and keep moving. NEVER pause to ask the user mid-pass — `TODO:` IS the unblock mechanism. Hand the reviewer concrete code with pinned questions, not a blank canvas.

## Anti-patterns

| Rationalization | Reality |
|-----------------|---------|
| "I'll invent a concise notation — `err ≠ nil → wrap`" | No unicode operators (PW-2). Every reputable corpus (Go proposals, Rust RFCs, Russ Cox essays) keeps real Go operators. Invented symbols rot — readers two years later can't tell `→` from `⇒` from `↦`. |
| "Python-style `:` + indent reads cleaner inside Go bodies" | No (PW-2). `:` already means case-label, struct field, composite-literal key in Go. Adding a fifth meaning creates local ambiguity and breaks every Go tool. |
| "I'll drop the LHS since `err` is obvious" | No (PW-5). Hidden variables age badly; the next reader doesn't know where `err` came from. Write `res, err := foo()` every time. |
| "Tag every TODO with `[group-name]: ...`" | No brackets (PW-3). Optional short ID after `TODO:` is enough: `// TODO: F1 do the thing`. Grep matches `rg 'TODO: F1'`. |
| "Every function needs a pseudocode body for completeness" | No (PW-7). If you can write the body, write it; if you cannot, mark it `TODO:`. Godoc-only stubs (zero-value body + "fill later") are obsolete — they were the old C shape, dropped under PW-9. |
| "TODO this if-branch — keeps the body short" | No (PW-9). `TODO:` is not a length-control tool. If the branch is decidable, write it. `TODO:` is reserved for unknowns and questions. |
| "I should stop and ask the user before writing the body" | No (PW-9). Don't block. Write what you can, drop a `TODO:` with the question. The reviewer prefers code-with-pinned-questions over an empty form they have to fill themselves. |
| "Domain logic is complex — let me TODO the whole use-case body" | No (PW-9 + layer table). Domain core is decidable: `if`/`switch`/error-wrapping/field-copy is the densest signal there is. Write it. Save `TODO:` for adapters where SQL / proto / generated detail is genuinely deferred. |

</IMPORTANT>

## North Star

This skill produces a **best-effort first pass** of a Go branch — for a Go-fluent reviewer who reads code faster than prose. Maximum signal = native Go. `TODO:` is a last resort, marking what cannot be written without information you do not have, or a decision you want the reviewer to make.

The 80/20 of prototyping speed: write the obvious code, mark the questions, never pause. The reviewer gets *concrete code with pinned questions* and can batch-resolve them on the way to L2 — instead of negotiating from a blank canvas.

### Code vs TODO by layer (defaults)

| Layer | Default | TODO acceptable when |
|-------|---------|----------------------|
| Contracts — types, fields, interfaces, errors, constants | Real code (always) | never (PW-4) |
| Domain core — use-cases, services, validators, mappers | **Real code** — `if`/`switch`/error wrapping/field copy written out | a specific decision is genuinely deferred (e.g. policy unknown, redaction list TBD) — pin to one site, not the whole body |
| Adapters in — grpc handlers, kafka consumers | Real code for routing/decoding/error mapping | external spec or proto field is unknown |
| Adapters out — repos, kafka producers, grpc clients | Real signature; body MAY be `TODO:` | SQL / proto / generated detail is deferred |
| Infra / wiring — `cmd/`, providers, DI | Real code — it is just assembly | almost never |

If you find yourself writing a `TODO:` inside a use-case branch, a mapper, or a validator — stop and write the code. That layer is decidable.

## Format — two shapes

Pick the lightest shape that carries the intent. **B is the default** — real Go body, `TODO:` only at genuine unknowns. **D** handles the rare TODO that needs a multi-line question.

### B — Real Go body with `// TODO:` markers at unknowns (DEFAULT)

Write everything you can. Place a `// TODO: <id?> <intent>` at the exact site where you need information you do not have, or a decision from the reviewer. Decidable code is never a `TODO:`.

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
        // TODO: F1 redact PII per security policy - which fields stay raw, which masked?
    }, nil
}
```

Why this works:
- Validation, error mapping, DTO construction — all decidable, all written. Reader sees the full control flow as Go.
- One `TODO:` pins the only genuine unknown (PII redaction policy). It is a question for the reviewer, not a placeholder for laziness.
- `F1` is a short optional feature ID. Reader greps `TODO: F1` to see the whole feature surface across files.

### D — Multi-line `/* TODO: ... */` block for a multi-line question

Use when a single `TODO:` needs 2-5 lines of prose because the question itself is multi-dimensional. One block per function, maximum two.

```go
func (x *UserService) DeleteUser(ctx context.Context, id string, hard bool) error {
    /* TODO: F2 permission policy - confirm matrix
       - !admin && hard          -> ErrForbidden ?
       - !admin && !hard && own  -> allow ?
       - admin                   -> allow both ?
    */

    if hard {
        if err := x.repo.HardDelete(ctx, id); err != nil {
            return fmt.Errorf("HardDelete(%s): %w", id, err)
        }
        // TODO: F2 emit UserPurged kafka event - topic + payload TBD
        return nil
    }

    if err := x.repo.SoftDelete(ctx, id, time.Now()); err != nil {
        return fmt.Errorf("SoftDelete(%s): %w", id, err)
    }
    // TODO: F2 emit UserDeleted kafka event - topic + payload TBD
    return nil
}
```

The branch structure (hard vs soft delete, error wrapping) is written out — that is decidable. The two open questions (permission policy + kafka event shape) are pinned with `TODO:` markers; the reviewer answers, the next pass fills them.

## Modifying existing code — inline `// TODO:` at change sites

When a diff touches existing code, place a one-line `// TODO: <id?> <intent>` at each change site. Existing code stays untouched; the marker pins what will change.

```go
func (x *UserService) UpdateUser(ctx context.Context, u *User) error {
    if err := u.Validate(); err != nil {
        return err
    }
    // TODO: AUD capture oldState before save (for audit log)
    oldState, err := x.repo.Get(ctx, u.ID)
    if err != nil {
        // TODO: AUD wrap with ErrInternal - audit fetch failure is non-retryable
        return err
    }
    if err := x.repo.Save(ctx, u); err != nil {
        return err
    }
    // TODO: AUD emit AuditEvent{op=update, before=oldState, after=u}
    return nil
}
```

Multiple TODOs in one body are fine for modifications (one per change site).

## Relationship to Other Skills

- `duperpowers-go:pseudocode-writer-test` — next skill in the pipeline (L1 → L1.5). Same TODO format applies inside test bodies.
- `duperpowers-go:go-writer-test` — not loaded here (production code only).

<IMPORTANT>

## Anchor

- **PW-1.** Load `go-writer` before editing `.go`
- **PW-2.** Real Go: native keywords and operators; no unicode, no `:`+indent
- **PW-3.** Hole-markers only: `// TODO:` one-liner or `/* TODO: */` block; optional short ID (no brackets)
- **PW-5.** Explicit LHS on assignments; no hidden provenance
- **PW-7.** Trivial bodies = write them, not godoc-stub
- **PW-8.** Invoke `verify L1` on completion. FAIL → fix, not declare.
- **PW-9.** Code-first, TODO-as-question — write what you can; `TODO:` marks unknowns/questions; never pause to ask

</IMPORTANT>
