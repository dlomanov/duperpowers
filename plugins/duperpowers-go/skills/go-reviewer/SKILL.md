---
name: go-reviewer
description: "Go code review (*.go files). Two modes: spec, quality. Structured PASS/FAIL verdicts with file:line evidence."
---

# Go Reviewer

Review Go code changes. Static analysis only — read code, never run it.

<IMPORTANT>

## Reviewer Rules

**RR-1.** Diff only — never flag unchanged code.
**RR-2.** No contradiction with duperpowers-go:go-writer / duperpowers-go:go-writer-test.
**RR-3.** No "while you're at it" scope creep.
**RR-4.** Uncertain → 👀 WARN, not 💥 ERR.
**RR-5.** Every ☠️ CRIT / 💥 ERR → addressable code (CRIT1, ERR2) + rule ID + │-wall code block with `// <- N` markers + explanations after block.
**RR-6.** Zero ☠️ CRIT + zero 💥 ERR → ✅ PASS.
**RR-7.** `Co-Authored-By: Claude*` in commits → ☠️ CRIT.
**RR-8.** Skip: `*.pb*.go`, `*mock*.go`, `swagger.*`, `mocks/`, `vendor/`, `docs/`, `bin/`, `third_party/`, migration SQL.

</IMPORTANT>

## Mode

One mode per invocation. Determined by dispatch:

- **spec** — verify step is fully delivered: every deliverable present, criteria met, no scope leak. Input: plan step + `git diff`.
- **quality** — verify code follows duperpowers-go:go-writer / duperpowers-go:go-writer-test conventions. Input: `git diff`.

For spec and quality: read changed files in full for context. Review scope = diff only.

## Spec Mode

Verify current step ONLY. Understand INTENT before checking boxes — a step that satisfies criteria but misses the point is ☠️ CRIT.

### Checklist

1. Every deliverable in `what` — present in diff
2. Every item in `criteria` — satisfiable by the code
3. All changes within declared `scope` — no unrelated files
4. No TODO / FIXME / stub in new code
5. No dead code introduced (unused types, funcs, vars)
6. No unrelated changes (drive-by refactoring)

Ambiguous criteria → check if ANY reasonable interpretation is satisfied → PASS. None satisfied → ☠️ CRIT.

Step says "implement X and Y", only X in diff → check if Y is in a later step. If not → ☠️ CRIT.

## Quality Mode

Review changed code. Skip generated and excluded files. Each check references duperpowers-go:go-writer / duperpowers-go:go-writer-test rule IDs.

### Errors

- **GP-3** Inline `errors.New` → should be sentinel `var errX`
- **GP-4** Unwrapped `return err` from function/method calls → `fmt.Errorf("callee: %w", err)`
- **ERR-3** `errors.As(err, &T{})` → should be `errorsx.Is[T]` (check `msgerrs`/`errorsx`)
- Swallowed errors: empty `if err != nil {}` or `_ = fn()` on fallible
- Error messages: lowercase, no punctuation, no "failed to"

### Code Structure

- **GP-1** Dead branches guarding impossible states (nil checks on DI deps)
- **GP-2** Sequential ifs on same result → should be bare `switch {}`. Exception: side-effect annotation (log/metric without own `return`)
- **PS-2** Models/tasks built inside `txmanager.Do` → should be built before

### Concurrency

- Context propagated, never created mid-chain
- Goroutines have lifetime (ctx, done, errgroup)
- Shared state synchronized
- No mutex held across I/O

### Layout

- **LY-1** Unexported above exported, or callees above callers
- **LY-2** Interfaces in implementation files → should be in root package file. Unsorted groups → primitives → infrastructure → business
- **LY-3** Struct fields: business deps before infrastructure → generic/primitive first

### Naming & Style

- **SN-1** Non-standard receivers (not `x` for structs, not `r` for repo, not `v` for lambdas)
- **SN-2** Name stutter with package (`order.OrderService`)
- **SN-3** 3+ scattered `:=` → should be `var(...)` block
- **STY-1** Line > 120 chars or > 3 args on one line
- **STY-2** > 2 struct fields initialized on one line
- **STY-3** WHAT comments (restating code) → only `// WHY:` allowed
- **STY-4** `interface{}` instead of `any`. Invented abbreviations

### Modern Go

- **MG-1** if/else chain for defaults → `cmp.Or()`
- **MG-2** `omitempty` on `time.Time`, `time.Duration`, structs → `omitzero`
- **MG-3** `wg.Add(1)` + `go func() { defer wg.Done()` → `wg.Go()`

### Tests

- **TG-3** if/else for error check → `assert.ErrorIs`. `var errTest` → `assert.AnError`
- **TG-4** Success case not last
- **TG-5** Concrete mock values in failure cases → should be `mock.Anything`
- **TM-2** Inline mock chains → break after `EXPECT().`, one method per line
- **TM-3** `t.Helper()` in `makeSUT`/`makeService`/`makeMocks` → never add, these are unconditional exceptions
- **TT-5** Compact one-line struct literals → always multi-line
- **TD-2** Repeated literals across cases → shared `var(...)` block
- **TS-1** Missing `t.Parallel()`. `context.Background()` → `t.Context()`
- **TS-2** Wrong naming: `happy_path` → `"success"`. Underscores in case names → spaces
- **TT-4** Case comments restating name → should explain WHY (Russian). Do NOT flag missing comments
- **TT-3** Business logic in `before` → should be mock setup only
- New exported func/method without test → 💥 ERR

### Red Flags

- Unbounded alloc in hot path (no cap hint)
- N+1 queries (DB call in loop)
- Unvalidated input at system boundary
- Hardcoded secrets or credentials

### Ignore

- gofmt / goimports whitespace and import ordering
- Unchanged code outside diff
- Missing comments (duperpowers-go:go-writer STY-3: zero by default)
- "Nice to have" improvements
- Hypothetical future problems
- Test coverage for unexported helpers (judgment call)

## Output

```
MODE: spec | quality
SUMMARY: 1-2 sentences proving you understood the change
VERDICT: ✅ PASS | ❌ FAIL
SCORE: 1-100

ISSUES:

CRIT1☠️ (RULE-ID) short description
  ...
ERR1💥 (RULE-ID) short description
  ...
WARN1👀 (RULE-ID) observation (code optional)

NOTES: (optional, ✅ PASS only, max 2)
```

**SUMMARY** = prove comprehension. If you can't summarize what the change does — you didn't review it.

### Issue Format

Issues use addressable codes (CRIT1, ERR2, WARN3), sorted by severity (☠️ → 💥 → 👀), most impactful first.

Every ☠️ CRIT / 💥 ERR MUST include:
- Addressable code + rule ID + short description
- File path above │-wall code block
- `// <- N` markers on problem lines
- Numbered explanations after the block

👀 WARN: code block optional — include only when the issue is unclear without it.

GOOD — addressable code, │-wall, markers, explanations after block:

```
ERR1💥 (GP-2) sequential ifs on same result

  handler.go:31

  │ res, err := repo.Find(ctx, id)
  │ if err != nil {           // <- 1
  │     return err
  │ }
  │ if res == nil {           // <- 2
  │     return ErrNotFound
  │ }

  1 two ifs on same result (res, err) → bare switch
  2 separate branch on same result
```

BAD — no code, no markers, explanation crammed into one line:

```
1. 💥 ERR handler.go:31 — (GP-2) sequential ifs on same result → should be bare switch
```

GOOD — multiple files in one issue:

```
ERR2💥 inconsistent ID validation

  cancel_order.go:42

  │ if req.GetStoreId() <= 0 { // <- 1

  create_order.go:43

  │ if req.GetStoreId() == 0 { // <- 2

  1 CancelOrder checks `<= 0`
  2 other handlers use `== 0` → negative IDs pass through
```

BAD — multiple files without code:

```
2. 💥 ERR cancel_order.go:42, create_order.go:43 — inconsistent validation `<= 0` vs `== 0`
```

GOOD — WARN without code (issue is clear without context):

```
WARN1👀 (STY-3) get_delivery_map.go:15 — WHAT comment "// get points from API"
```

GOOD — WARN with code (issue is unclear without context):

```
WARN2👀 relative path to asset

  connect_ozon_logistics.go:15

  │ const defaultLogoPath = "assets/default_logo.png" // <- 1

  1 depends on working directory, prefer go:embed
```

BAD — WARN always with code (wastes tokens):

```
3. 👀 WARN connect_ozon_logistics.go:15
   │ const defaultLogoPath = "assets/default_logo.png"
   fragile relative path
```

### Score Guide

| Range | Meaning |
|-------|---------|
| 95-100 | Clean, no issues |
| 85-94 | ✅ PASS with minor warns |
| 70-84 | ✅ PASS but notable concerns |
| <70 | ❌ FAIL |

### Severity

| Level | Meaning | Verdict |
|-------|---------|---------|
| ☠️ CRIT | Security, data loss, correctness bugs | → ❌ FAIL |
| 💥 ERR | Architecture, missing logic, error handling | → ❌ FAIL |
| 👀 WARN | Observations, suggestions | ✅ PASS ok |

<IMPORTANT>

## Self-Check (Anchor)

Before outputting verdict:
- SUMMARY proves comprehension (not generic filler)
- Reviewed entire diff, not just first file
- Skipped generated / excluded files (RR-8)
- Every ☠️ CRIT / 💥 ERR has addressable code + │-wall code block with `// <- N` markers (RR-5)
- Issues use addressable codes (CRIT1, ERR2, WARN3), sorted by severity
- No flags on unchanged code (RR-1)
- No contradiction with duperpowers-go:go-writer / duperpowers-go:go-writer-test (RR-2)
- No scope creep (RR-3)
- Spec: verified current step only, understood intent
- VERDICT matches: ≥1 CRIT or ERR = FAIL, else PASS (RR-6)
- SCORE consistent: 0 issues → 95+, WARNs only → 70-94, any ERR/CRIT → <70

</IMPORTANT>
