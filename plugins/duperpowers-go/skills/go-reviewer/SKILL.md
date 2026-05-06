---
name: go-reviewer
description: "Go code review (*.go files). Structured PASS/FAIL verdicts with file:line evidence. Compose with `superpowers:requesting-code-review` per `superpowers-overrides`."
---

# Go Reviewer

<IMPORTANT>

## Reviewer Rules

**RR-1.** Review scope ALWAYS expands ONE LEVEL UP and ONE LEVEL DOWN from the change. This is the core mechanic — every other review rule operates within this scope.

ONE LEVEL UP — from change to its container, then across all siblings/usages at that level:

| Change | Up (container) | Across (siblings/usages) |
|--------|---------------|--------------------------|
| line | function/method | all lines in that function |
| function/method | package | all callers in the package |
| signature / contract | — | all implementations + all callers |
| struct field | — | all usages of the struct |
| proto field | — | all response messages → all RPC methods |

ONE LEVEL DOWN — from change into callees, then across all methods/functions of the same type:

| Change | Down (callee) | Across (sibling methods) |
|--------|--------------|--------------------------|
| call `x.Method()` | Method implementation | all methods of x's type |
| call `Func(args)` | Func implementation | — |
| guard + call | callee's internal guards | same guard pattern in sibling callees |

- ALWAYS inspect callee implementation — verify caller does not duplicate callee's internal guard
- When code calls `instance.Method()` — ALWAYS review ALL methods of that type, not just the called one

SCOPE-DOWN MANDATORY CHECKS:

CHECK A — `if <condition> { callee() }` where callee has same condition internally → redundant guard
CHECK B — `validate(x)` before `parse(x)` where parse returns checked error → redundant pre-validation
CHECK C — `type.PredicateA()` used → read ALL predicate methods of that type, verify correct one chosen
**RR-2.** No contradiction with duperpowers-go:go-writer / duperpowers-go:go-writer-test.
**RR-3.** No "while you're at it" scope creep. Issues found within RR-1 scope (UP/DOWN/ACROSS) are in-scope; do not flag issues outside RR-1 boundaries.
**RR-4.** Uncertain → 👀 WARN, not 💥 ERR.
**RR-5.** Every ☠️ CRIT / 💥 ERR → addressable code (CRIT1, ERR2) + rule ID + │-wall code block with `// <- N` markers + explanations after block.
**RR-6.** Zero ☠️ CRIT + zero 💥 ERR → ✅ PASS.
**RR-7.** `Co-Authored-By: Claude*` in commits → ☠️ CRIT.
**RR-8.** Skip: `*.pb*.go`, `*mock*.go`, `swagger.*`, `mocks/`, `vendor/`, `docs/`, `bin/`, `third_party/`, migration SQL.

</IMPORTANT>

## Procedure

Caller (user or composing skill) invokes the reviewer; the body of this skill IS the review procedure. Review changed code. Skip generated and excluded files.

### Scope

The review checks the diff against every rule in `duperpowers-go:go-writer` (production code) and `duperpowers-go:go-writer-test` (test code). Rule IDs (`GP-*`, `SN-*`, `LY-*`, `ERR-*`, `STY-*`, `MG-*`, `PS-*` for production; `TG-*`, `TS-*`, `TT-*`, `TM-*`, `TF-*`, `TA-*` for tests) live in those skills. Do not duplicate them here.

Skip items listed in `### Ignore` below.

### Concurrency

- context propagated, never created mid-chain
- goroutines have lifetime (ctx, done, errgroup)
- shared state synchronized, no mutex across I/O

### Red Flags

- unbounded alloc in hot path (no cap hint)
- N+1 queries (DB call in loop)
- unvalidated input at system boundary
- hardcoded secrets

### Ignore

- gofmt/goimports whitespace
- code outside RR-1 scope
- missing comments (STY-3: zero by default)
- "nice to have", hypothetical future problems

## Output

```
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
- Scope expansion applied: UP + DOWN + ACROSS (RR-1)
- No contradiction with duperpowers-go:go-writer / duperpowers-go:go-writer-test (RR-2)
- No scope creep (RR-3)
- VERDICT matches: ≥1 CRIT or ERR = FAIL, else PASS (RR-6)
- SCORE consistent: 0 issues → 95+, WARNs only → 70-94, any ERR/CRIT → <70

</IMPORTANT>
