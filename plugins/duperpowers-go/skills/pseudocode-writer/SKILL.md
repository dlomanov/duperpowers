---
name: pseudocode-writer
description: "Use when writing production pseudocode (L0 → L1 transition of pseudocode-pipeline). Produces Go skeletons with real-Go contracts and TODO: markers at exact code locations."
---

# Pseudocode Writer

<IMPORTANT>

## Golden Rules

- **PW-1.** MUST invoke `duperpowers-go:go-writer` before editing any `.go` file. Go conventions apply to all real-Go parts.
- **PW-2.** `TODO:` at the exact code location, two forms:
  - Block `/* TODO[group]: ... */` inside new function bodies — exactly one per body, alongside zero-value return. No real implementation mixed in.
  - Inline `// TODO[group]: ...` at each change site in existing code — multiple per body OK.
- **PW-3.** Real Go (compile-checked) for: signatures, types, fields, models, interfaces, enums, constants. These must not be stubs.
- **PW-4.** Audience = user. No agent-specific sections, no USER/AGENT labels. If the user understands, sonnet understands.
- **PW-5.** Group tag `[group-tag]` is optional. Use when a change spans multiple files/funcs and grep-coherence matters. Single-file single-func changes may omit it.
- **PW-6.** Symbol set: see §Symbol Reference. Do NOT use `∧ ∨ ¬` or invented notation.
- **PW-7.** On completion MUST invoke `duperpowers-go:verify` with target=L1. On FAIL, fix missing guarantees before declaring completion. Do NOT declare L1 without PASS.

## North Star

Pseudocode so readable the user would rather hand-write than review. Real identifiers (`repo.Get`, not "the repo"); one logical step per line; control flow through indent and `→`, not prose.

## Anti-patterns

| Rationalization | Reality |
|-----------------|---------|
| "I'll write abstract pseudo like 'handle the error'" | Too vague. Use `err = ErrNotFound → wrap domain.ErrUserNotFound`. Concrete wins. |
| "Let me add an 'agent:' section for extra details" | No — single audience. If the detail matters to the user, write it inline. If not, drop it. |
| "Multiple TODO blocks in one new body looks cleaner" | New bodies: one block. Multiple is for existing-code modifications only. |

</IMPORTANT>

## Format

### Block TODO — new function body (one block per body)

```go
func (x *UserService) GetUser(ctx context.Context, id string) (*UserDTO, error) {
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
func (x *UserService) UpdateUser(ctx context.Context, u *User) error {
    if err := u.Validate(); err != nil {
        return err
    }
    // TODO[user-audit]: capture old user state before save (for audit log)
    oldState, err := x.repo.Get(ctx, u.ID)
    if err != nil {
        // TODO[user-audit]: wrap with ErrInternal — audit fetch failure is non-retryable
        return err
    }
    if err := x.repo.Save(ctx, u); err != nil {
        return err
    }
    // TODO[user-audit]: emit AuditEvent{op=update, before=oldState, after=u}
    return nil
}
```

### Block TODO — nested decision tree

```go
func (x *UserService) DeleteUser(ctx context.Context, id string, hard bool) error {
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

## Relationship to Other Skills

- `duperpowers-go:pseudocode-writer-test` — next skill in the pipeline (L1 → L1.5).
- `duperpowers-go:go-writer-test` — not loaded here (production code only).

<IMPORTANT>

## Anchor

- **PW-1.** Load `go-writer` before editing `.go`
- **PW-2.** `TODO:` at exact code location — block for new bodies (one per body + zero-value return), inline for existing-code mods
- **PW-3.** Real Go for contracts
- **PW-4.** Single audience = user
- **PW-7.** Invoke `verify L1` on completion. FAIL → fix, not declare.

</IMPORTANT>
