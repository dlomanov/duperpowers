---
name: pseudocode-writer-test
description: "Use when writing test pseudocode (L1 → L1.5 transition of pseudocode-pipeline). Produces *_test.go files with populated cases tables (real Go) and TODO: markers inside t.Run / setup closures. MUST invoke duperpowers-go:go-writer-test before editing any _test.go file. Precondition: branch at L1 — skill invokes duperpowers-go:verify L1 first. On completion MUST invoke duperpowers-go:verify with L1.5 target."
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

Populated cases tables close the "what are we testing" question on paper, before implementation. By the time the user reads the test, the space of behaviors (branches, validations, error paths) is already enumerated — the only remaining work is filling `t.Run` bodies with assertions. If a table is dense and the bodies are thin `TODO:` stubs, the skill hit its mark.

- One case per behavior, not per field (per TG-6 in `go-writer-test`)
- Case order: simple → complex → success LAST (per TG-4)
- Concrete mock args only in `success`; `mock.Anything` in failure cases (per TG-5)
- Shared values in `var(...)` above the table (per TF-2)

## Anti-patterns

| Rationalization | Reality |
|-----------------|---------|
| "I'll just leave cases table with TODO rows" | No — rows ARE the design (PWT-3). Table shape decides what behaviors exist; fill rows now. |
| "`t.Run` body should call `sut.Method` already for realism" | Not required. A `TODO:` block that describes the call + assertions is enough — bodies get filled at L2. |
| "I'll skip `verify L1` — user said they finished L1" | PWT-2 is mandatory. L1 claim without PASS is not a PASS. |
| "I can use `t.Skip` / `t.Fatal` as a placeholder" | No — those run. Leave body empty except for `TODO:`; compiles without failing. |
| "One case per propagated field — clearer" | TG-6 forbids this. A new field extends the existing `success` case; a new *behavior* justifies a new case. |
| "`go-writer-test` is for full tests, pseudocode is different" | No. The conventions apply to real-Go parts of the test (table shape, mock chain, naming). Loading is cheap. |
| "Verify can wait — I'll finish all tests first" | PWT-7 is mandatory. A transition is incomplete without its safety gate. |

</IMPORTANT>

## Purpose

L1 → L1.5 transition for the pseudocode-pipeline. Produces `*_test.go` files where:
- Test function signatures, `cases` tables, mock chains, and SUT construction are real Go and compile-checked.
- `t.Run` bodies and setup closures carry `TODO:` markers (or partial real-Go) describing intended assertions.
- Modifications to existing tests are annotated with inline `// TODO[group]:` at each change site.
- The branch reaches L1.5 guarantees (see spec §4): G1.5.1 test file per new exported func; G1.5.2 populated cases; G1.5.3 scaffolding or TODO in closures; G1.5.4 TODO at modification sites; G1.5.5 `go test -count=0 ./...` compiles.

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
        // пустой id — валидация отсекает на входе, репо не дергается
        {
            name:    "empty id",
            wantErr: ErrInvalidID,
        },
        // репо вернул NotFound — доменная ошибка, не internal
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
        // любая другая ошибка репо → оборачиваем в ErrInternal
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
        // все зависимости отработали — собран DTO через mapper
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
        // TODO[user-tags]: добавить Tags в expected - поле прилетает из DTO
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
                    // TODO[user-tags]: matcher - Save получает u с правильными Tags
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

## Symbol Reference

Inherited from `duperpowers-go:pseudocode-writer` — do NOT invent notation.

| Symbol | Meaning |
|--------|---------|
| `→` | transition / result / outcome |
| `=` | equals |
| `≠` | not equal |
| `&` | and |
| `\|` | or |
| `!` | not |

Blank lines separate major phases inside a `TODO:` block. Indentation shows branch / dependency hierarchy.

## Process

1. Read the prod pseudocode from the L1 branch state — identify new exported functions/methods requiring tests.
2. Invoke `duperpowers-go:verify L1` — must be PASS before editing tests (PWT-2). On FAIL: STOP, report missing L1 guarantees, hand back to user.
3. Invoke `duperpowers-go:go-writer-test` before any `_test.go` edit (PWT-1).
4. For each new exported function:
   - Create `*_test.go` alongside prod file (same package, whitebox per TS-2).
   - Write test function signature: `func TestType_Method(t *testing.T) { t.Parallel(); ... }` (real Go).
   - Write populated `cases` table per TG-4 order (simple → complex → success last), per TG-5 mock specificity, per TG-6 one case per behavior.
   - In each `before` closure and in `t.Run` body: either real-Go setup OR a `TODO:` block describing mock chain / assertions.
5. For each modified existing test in the diff: insert inline `// TODO[group]:` at change sites (PWT-5).
6. Once all planned test sites have tables + markers: invoke `duperpowers-go:verify L1.5` (PWT-7).
7. On `verify` FAIL: fix missing guarantees (usually: missing `*_test.go` file, empty rows, or closures without TODO). Re-verify.
8. On `verify` PASS: declare L1.5 reached; hand control back to user.

## L1.5 Guarantees Produced

Tracked by `duperpowers-go:verify`. All of (from spec §4 + `verify` SKILL.md):

- **G1.1-G1.5** (all L1 guarantees, re-checked)
- **G1.5.1** Each new exported function/method in the diff has a corresponding `*_test.go` file
- **G1.5.2** Test functions contain a populated `cases` slice (non-empty rows with name, input, expected)
- **G1.5.3** `t.Run` and setup closures contain `TODO:` markers or real-Go scaffolding
- **G1.5.4** Existing tests modified in the diff carry `TODO:` markers at modification sites
- **G1.5.5** `go test -count=0 ./...` compiles (failures allowed; bodies unimplemented)

`verify` is authoritative — this list is a reader-convenience summary only.

## Relationship to Other Skills

- `duperpowers-go:go-writer-test` — mandatory pre-load (PWT-1). Provides test conventions (TG-*, TS-*, TT-*, TM-*, TF-*).
- `duperpowers-go:verify` — invoked twice: at start with target L1 (PWT-2 precondition), at completion with target L1.5 (PWT-7).
- `duperpowers-go:pseudocode-writer` — prior skill (L0 → L1). Shares format conventions (TODO: block/inline, symbol set, single-audience rule).
- `duperpowers-go:go-writer` — not used here (tests only).
- `duperpowers-go:go-reviewer` — not invoked; review is optional at L1/L1.5 per spec §9.

<IMPORTANT>

## Anchor

- **PWT-1.** Load `go-writer-test` before editing `_test.go`
- **PWT-2.** Precondition `verify L1` = PASS. Not PASS → STOP.
- **PWT-3.** Cases tables populated real Go. Rows are the design.
- **PWT-4.** `t.Run` body + setup closures: real Go OR `TODO:` block. No panicking stubs.
- **PWT-5.** Existing-test mods: inline `// TODO[group]:` at each change site.
- **PWT-7.** Invoke `verify L1.5` on completion. FAIL → fix, not declare.

</IMPORTANT>
