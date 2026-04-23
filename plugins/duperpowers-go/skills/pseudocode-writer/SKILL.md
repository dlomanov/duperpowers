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
- **PW-7.** Prefer signature + godoc comment for trivial functions; reserve body pseudocode for novel control flow. Not every function earns a sketched body.
- **PW-8.** On completion MUST invoke `duperpowers-go:verify` with target=L1. On FAIL, fix missing guarantees before declaring completion. Do NOT declare L1 without PASS.

## Anti-patterns

| Rationalization | Reality |
|-----------------|---------|
| "I'll invent a concise notation — `err ≠ nil → wrap`" | No unicode operators (PW-2). Every reputable corpus (Go proposals, Rust RFCs, Russ Cox essays) keeps real Go operators. Invented symbols rot — readers two years later can't tell `→` from `⇒` from `↦`. |
| "Python-style `:` + indent reads cleaner inside Go bodies" | No (PW-2). `:` already means case-label, struct field, composite-literal key in Go. Adding a fifth meaning creates local ambiguity and breaks every Go tool. |
| "I'll drop the LHS since `err` is obvious" | No (PW-5). Hidden variables age badly; the next reader doesn't know where `err` came from. Write `res, err := foo()` every time. |
| "Tag every TODO with `[group-name]: ...`" | No brackets (PW-3). Optional short ID after `TODO:` is enough: `// TODO: F1 do the thing`. Grep matches `rg 'TODO: F1'`. |
| "Every function needs a pseudocode body for completeness" | No (PW-7). Trivial functions get signature + godoc prose; reserve the body sketch for novel control flow. Google design-doc guidance: "Design docs should rarely contain code or pseudo-code except for novel algorithms." |

</IMPORTANT>

## Format — three shapes ranked by preference

The user reviewing your pseudocode should feel they are reading Go. Pick the lightest shape that carries the intent. B is the default; D handles multi-line intent; C handles trivial functions.

### B — Real Go body with `// TODO:` markers (DEFAULT)

Realistic control flow. Each unfilled step is a one-line `// TODO: <id?> <intent>`. Fill the steps where the control flow is trivially implied; leave TODO where the implementation matters.

```go
func (x *UserService) GetUser(ctx context.Context, id string) (*UserDTO, error) {
    // TODO: F1 validate id - reject empty / whitespace -> ErrInvalidID

    u, err := x.repo.Get(ctx, id)
    if errors.Is(err, repository.ErrNotFound) {
        return nil, ErrUserNotFound
    }
    if err != nil {
        return nil, fmt.Errorf("GetUser(%s): %w", id, err)
    }

    // TODO: F1 map u -> *UserDTO (copy public fields, redact PII)
    return nil, nil
}
```

Why this works:
- Signatures compile. Error-mapping control flow is real. Two TODOs at the exact sites needing implementation.
- `F1` is a short optional feature ID. Reader greps `TODO: F1` to see the whole feature surface.
- No unicode, no invented operators, no `:`+indent. Reads as Go because it is Go.

### D — Multi-line `/* TODO: ... */` block

Use when a single TODO needs 2-5 lines of prose to describe nested logic. One block per function, maximum two.

```go
func (x *UserService) DeleteUser(ctx context.Context, id string, hard bool) error {
    /* TODO: F2 permission check
       - !admin && hard          -> ErrForbidden
       - !admin && !hard && own  -> allow
       - admin                   -> allow both
    */

    if hard {
        if err := x.repo.HardDelete(ctx, id); err != nil {
            return fmt.Errorf("HardDelete(%s): %w", id, err)
        }
        // TODO: F2 emit UserPurged kafka event
        return nil
    }

    if err := x.repo.SoftDelete(ctx, id, time.Now()); err != nil {
        return fmt.Errorf("SoftDelete(%s): %w", id, err)
    }
    // TODO: F2 emit UserDeleted kafka event
    return nil
}
```

### C — Signature + godoc comment only (for trivial functions)

When control flow is boring, the whole pseudocode step is an intent-level godoc comment. No body pseudocode.

```go
// GetUserName fetches the user's display name by id.
// Returns ErrInvalidID for empty ids, ErrUserNotFound when the
// repository has no record, and wraps any other repository error.
//
// TODO: F3 fill body.
func (x *UserService) GetUserName(ctx context.Context, id string) (string, error) {
    return "", nil
}
```

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
- **PW-8.** Invoke `verify L1` on completion. FAIL → fix, not declare.

</IMPORTANT>
