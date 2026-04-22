---
name: pseudocode-writer-test
description: "Use when writing test pseudocode (L1 → L1.5 transition of pseudocode-pipeline). Produces *_test.go files with populated cases tables and TODO: markers inside t.Run / setup closures."
---

# Pseudocode Writer Test

<IMPORTANT>

## Golden Rules

- **PWT-1.** MUST invoke `duperpowers-go:go-writer-test` before editing any `_test.go` file. All test conventions (TG-*, TS-*, TT-*, TM-*, TF-*) apply to real-Go parts of the test.
- **PWT-2.** Precondition: branch must be at L1. Invoke `duperpowers-go:verify L1` first. If verdict ≠ PASS, STOP and report blocking guarantees — do not edit tests. User fixes L1 first (typically via `duperpowers-go:pseudocode-writer`).
- **PWT-3.** Cases tables are populated real Go. Every row has a concrete `name`; concrete `args` / `want` / `wantErr` are filled per table schema (zero-value `want` spelled out per TT-6). No empty rows, no `// TODO: fill row later` stubs — rows are the design.
- **PWT-4.** `t.Run` body and setup closures (`before`, `makeSUT` customizations) carry either real-Go scaffolding OR a `TODO:` block describing intended setup / call / assertion. No panicking stubs and no failing placeholders; comment-only TODO keeps the body empty so `go test -count=0 ./...` compiles.
- **PWT-5.** Modifications to existing tests use inline `// TODO[group]: ...` at each change site. Multiple per test body are OK — one per change point.
- **PWT-6.** Audience = user. No USER/AGENT labels, no agent-specific sections. Same top-down density as `duperpowers-go:pseudocode-writer` — if the user reads fluently, sonnet reads fluently.
- **PWT-7.** On completion MUST invoke `duperpowers-go:verify` with target=L1.5. On FAIL, fix missing guarantees before declaring completion. Do NOT declare L1.5 without PASS.

## North Star

Populated cases tables close "what are we testing" on paper before implementation. Case order simple → complex → success LAST (TG-4); concrete mock args only in `success` (TG-5); one case per behavior (TG-6); shared values in `var(...)` above the table (TF-2).

## Anti-patterns

| Rationalization | Reality |
|-----------------|---------|
| "I'll just leave cases table with TODO rows" | No — rows ARE the design (PWT-3). Table shape decides what behaviors exist; fill rows now. |
| "`t.Run` body should call `sut.Method` already for realism" | Not required. A `TODO:` block that describes the call + assertions is enough — bodies get filled at L2. |
| "I can use `t.Skip` / `t.Fatal` as a placeholder" | No — those run. Leave body empty except for `TODO:`; compiles without failing. |
| "One case per propagated field — clearer" | TG-6 forbids this. A new field extends the existing `success` case; a new *behavior* justifies a new case. |

</IMPORTANT>

## Format

### New test file — populated cases + TODO in `t.Run` body

Reading the prod code skeleton (from L1): `UserService.GetUser(ctx, id) (*UserDTO, error)` — returns domain error on miss, wraps on internal error, maps user → DTO on success.

```go
func TestUserService_GetUser(t *testing.T) {
    t.Parallel()

    var (
        id       = gofakeit.UUID()
        expected = &UserDTO{ID: id, Name: "jane"}
    )

    type args = string
    tests := []struct {
        name    string
        args    args
        before  func(args args, m mockList)
        want    *UserDTO
        wantErr error
    }{
        // empty id - validation rejects at entry, repo is not called
        {
            name:    "empty id",
            wantErr: ErrInvalidID,
        },
        // repo returned NotFound - domain error, not internal
        {
            name: "not found",
            args: id,
            before: func(_ args, m mockList) {
                /* TODO[get-user]:
                   m.repo.EXPECT().Get(mock.Anything, mock.Anything)
                     → Return(nil, domain.ErrUserNotFound)
                     → Once
                */
            },
            wantErr: domain.ErrUserNotFound,
        },
        // any other repo error - wrap in ErrInternal
        {
            name: "repo error",
            args: id,
            before: func(_ args, m mockList) {
                /* TODO[get-user]:
                   m.repo.EXPECT().Get(mock.Anything, mock.Anything)
                     → Return(nil, assert.AnError)
                     → Once
                */
            },
            wantErr: assert.AnError,
        },
        // all dependencies succeeded - DTO built via mapper
        {
            name: "success",
            args: id,
            before: func(a args, m mockList) {
                /* TODO[get-user]:
                   m.repo.EXPECT().Get(mock.Anything, a)
                     → Return(&User{ID: a}, nil)
                     → Once
                   m.mapper.EXPECT().ToUserDTO(mock.Anything)
                     → Return(expected)
                     → Once
                */
            },
            want: expected,
        },
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()

            sut, m := makeSUT(t)
            if tt.before != nil {
                tt.before(tt.args, m)
            }

            /* TODO[get-user]:
               got, err := sut.GetUser(t.Context(), tt.args)
               assert.Equal(t, tt.want, got)
               assert.ErrorIs(t, err, tt.wantErr)
            */
        })
    }
}
```

Why this shape:
- Table is real Go (compile-checked): case struct, rows populated, `before` signatures correct.
- Closures and `t.Run` body keep `TODO:` blocks — bodies compile because TODO is a comment.
- `success` has concrete mock args (`a`); failures use `mock.Anything` (per TG-5).
- Case order: `empty` → `not found` → `repo error` → `success` last (per TG-4).

### Modifying existing tests — inline `TODO:` at change sites

A new propagated field `Tags` appears on `User.Save`. Existing test needs a new mock expectation and an assertion tweak. Per TG-6 do NOT add a "success with tags" case — extend `success` instead. Annotate the change points:

```go
func TestUserService_Create(t *testing.T) {
    t.Parallel()

    var (
        id       = gofakeit.UUID()
        // TODO[user-tags]: add Tags to expected - field comes from DTO
        expected = User{ID: id}
    )

    type args = CreateUserInput
    tests := []struct {
        name    string
        args    args
        before  func(a args, m mockList)
        want    User
        wantErr error
    }{
        {
            name:    "empty name",
            wantErr: ErrEmptyName,
        },
        {
            name: "success",
            args: args{ID: id},
            before: func(a args, m mockList) {
                m.repo.EXPECT().
                    // TODO[user-tags]: matcher - Save gets u with correct Tags
                    Save(mock.Anything, mock.Anything).
                    Return(expected, nil).
                    Once()
            },
            want: expected,
        },
    }
    // ...
}
```

Inline markers at each change point; the test compiles untouched; user fills the marked spots on the way to L2.

Symbol set inherited from `duperpowers-go:pseudocode-writer` §Symbol Reference. Do NOT invent notation.

## Relationship to Other Skills

- `duperpowers-go:pseudocode-writer` — prior skill (L0 → L1). Shares format conventions (TODO: block/inline, symbol set).
- `duperpowers-go:review` — optional at L1.5 per spec §9; user may invoke ad-hoc.

<IMPORTANT>

## Anchor

- **PWT-1.** Load `go-writer-test` before editing `_test.go`
- **PWT-2.** Precondition `verify L1` = PASS. Not PASS → STOP.
- **PWT-3.** Cases tables populated real Go. Rows are the design.
- **PWT-4.** `t.Run` body + setup closures: real Go OR `TODO:` block. No panicking stubs.
- **PWT-5.** Existing-test mods: inline `// TODO[group]:` at each change site.
- **PWT-7.** Invoke `verify L1.5` on completion. FAIL → fix, not declare.

</IMPORTANT>
