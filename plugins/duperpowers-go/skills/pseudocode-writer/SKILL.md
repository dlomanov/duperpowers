---
name: pseudocode-writer
description: "Use when writing production pseudocode (L0 → L1 transition of pseudocode-pipeline). Produces Go skeletons where contracts are real Go and unfinished bodies carry TODO: markers at exact code locations. MUST invoke duperpowers-go:go-writer before editing any .go file. On completion MUST invoke duperpowers-go:verify with L1 target."
---

# Pseudocode Writer

<IMPORTANT>

## Golden Rules

- **PW-1.** MUST invoke `duperpowers-go:go-writer` before editing any `.go` file. Go conventions apply to all real-Go parts.
- **PW-2.** Pseudocode lives at the exact code location. Use `/* TODO[group]: ... */` for multi-line blocks inside new function bodies; use `// TODO[group]: ...` for inline single-line directives (especially when modifying existing code).
- **PW-3.** Real Go (compile-checked) for: signatures, types, fields, models, interfaces, enums, constants. These must not be stubs.
- **PW-4.** New function bodies return zero-value only, with exactly one block `TODO:` describing intended behavior. No partial implementation mixed in.
- **PW-5.** Modifications to existing code: inline `// TODO:` at each change site. Multiple TODOs per body are OK in this case.
- **PW-6.** Audience = user. No agent-specific sections, no USER/AGENT labels. If the user understands, sonnet understands.
- **PW-7.** Group tag `[group-tag]` is optional. Use when a change spans multiple files/funcs and grep-coherence matters. Single-file single-func changes may omit it.
- **PW-8.** Symbol set: `→ = ≠ & | !`. Use natural words where a symbol would obscure meaning. Do NOT use `∧ ∨ ¬` or invented notation.
- **PW-9.** On completion MUST invoke `duperpowers-go:verify` with target=L1. On FAIL, fix missing guarantees before declaring completion. Do NOT declare L1 without PASS.

## North Star

Pseudocode must be so readable that the user fights the urge to implement it themselves. That tension is the signal. If the reader isn't pulled toward hand-writing, pseudocode is too abstract.

- Use real identifiers (`repo.Get`, `mapper.ToUserDTO`), not placeholders ("the repo", "the mapper")
- One logical step per line
- Show control flow through indent and `→`, not through prose
- Complete sentences only when nuance requires

## Anti-patterns

| Rationalization | Reality |
|-----------------|---------|
| "I'll write abstract pseudo like 'handle the error'" | Too vague. Use `err = ErrNotFound → wrap domain.ErrUserNotFound`. Concrete wins. |
| "Let me add an 'agent:' section for extra details" | No — single audience. If the detail matters to the user, write it inline. If not, drop it. |
| "Multiple TODO blocks in one new body looks cleaner" | New bodies: one block. Multiple is for existing-code modifications only. |
| "I can skip the `go-writer` invocation, I know Go" | PW-1 is mandatory. Conventions drift; loading is cheap. |
| "Verify can wait until later" | PW-9 is mandatory. A transition is not complete without its safety gate. |

</IMPORTANT>

## Purpose

L0 → L1 transition for the pseudocode-pipeline. Produces Go files where:
- Contracts (signatures, types, fields, interfaces) are real Go and compile-checked
- Unfinished bodies carry `TODO:` markers describing the intended behavior
- The branch reaches L1 guarantees (see spec §4)

## Format

### Block TODO — new function body (one block per body)

```go
func (s *UserService) GetUser(ctx context.Context, id string) (*UserDTO, error) {
    /* TODO[get-user]:
       validate id
         empty     → ErrInvalidID
         non-empty → continue

       repo.Get(ctx, id)
         err = ErrNotFound → wrap domain.ErrUserNotFound
         err ≠ nil         → wrap ErrInternal(id, err)
         user != nil       → continue

       map user → UserDTO via mapper.ToUserDTO
       return dto, nil
    */
    return nil, nil
}
```

### Inline TODO — modifying existing code (one per change site, multiple OK)

```go
func (s *UserService) UpdateUser(ctx context.Context, u *User) error {
    if err := u.Validate(); err != nil {
        return err
    }
    // TODO[user-audit]: capture old user state before save (for audit log)
    oldState, err := s.repo.Get(ctx, u.ID)
    if err != nil {
        // TODO[user-audit]: wrap with ErrInternal — audit fetch failure is non-retryable
        return err
    }
    if err := s.repo.Save(ctx, u); err != nil {
        return err
    }
    // TODO[user-audit]: emit AuditEvent{op=update, before=oldState, after=u}
    return nil
}
```

### Block TODO — nested decision tree

```go
func (s *UserService) DeleteUser(ctx context.Context, id string, hard bool) error {
    /* TODO[user-delete]:
       check permissions
         !admin & hard          → ErrForbidden
         !admin & !hard & own   → allow
         admin                  → allow both

       hard
         repo.HardDelete(ctx, id) → on err wrap ErrInternal
         emit UserPurged kafka event
       !hard
         repo.SoftDelete(ctx, id, time.Now()) → on err wrap
         emit UserDeleted kafka event

       return nil
    */
    return nil
}
```

## Symbol Reference

| Symbol | Meaning |
|--------|---------|
| `→` | transition / result / outcome |
| `=` | equals |
| `≠` | not equal |
| `&` | and |
| `\|` | or |
| `!` | not |

Blank lines separate major phases. Indentation shows branch / dependency hierarchy.

## Process

1. Read the user's intent, spec, or brainstorm output
2. Invoke `duperpowers-go:go-writer` before any `.go` edit (PW-1)
3. Write real-Go contracts: types, fields, signatures, interfaces, enums
4. For new functions: add one block `/* TODO[group]: ... */` in body + zero-value return
5. For modifications: add inline `// TODO[group]: ...` at each change site
6. Once all planned code sites have TODO markers: invoke `duperpowers-go:verify L1`
7. On `verify` FAIL: fix missing guarantees (usually compile errors — add missing signatures / types / imports), re-verify
8. On `verify` PASS: declare L1 reached; hand control back to user

## L1 Guarantees Produced

Tracked by `verify` skill. All of:

- **G1.1** Public signatures of new/changed methods compile
- **G1.2** Types, fields, models, interfaces compile
- **G1.3** At least one `TODO:` marker present
- **G1.4** `gocheck` passes
- **G1.5** `dpcheck` passes (if available; warning if missing)

## Relationship to Other Skills

- `go-writer` — mandatory pre-load (PW-1). Provides Go conventions.
- `verify` — mandatory post-invoke (PW-9). Confirms L1 reached.
- `pseudocode-writer-test` — next skill (L1 → L1.5). Introduced in M2 milestone.
- `go-writer-test` — not used in this skill (production code only).

<IMPORTANT>

## Anchor

- **PW-1.** Load `go-writer` before editing `.go`
- **PW-2.** TODO at exact code location, block for new bodies, inline for existing-code edits
- **PW-3.** Real Go for contracts
- **PW-4.** New bodies: one block TODO + zero-value return, no mixed impl
- **PW-6.** Single audience = user
- **PW-9.** Invoke `verify L1` on completion. FAIL → fix, not declare.

</IMPORTANT>
