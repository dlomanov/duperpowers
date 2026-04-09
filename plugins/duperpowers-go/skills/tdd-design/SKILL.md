---
name: tdd-design
description: "Use when writing test design during planning phase — before any execution steps. Produces test case table with hints for sonnet implementation."
---

# TDD Design

<IMPORTANT>

## Golden Rules

**TD-1.** Test design is a planning artifact. Opus writes it, user reviews it, sonnet implements it.
**TD-2.** Minimal intervention. Prefer adding cases to existing tests over creating new files. Prefer modifying existing cases over adding new ones. New test file only when no suitable test exists.
**TD-3.** Invoke go-writer-test AND go-writer before writing hints. Go code in hints follows go-writer conventions. Test patterns follow go-writer-test conventions. Sonnet copies patterns from your examples.
**TD-4.** Ask user before writing: reference test file (best test in the project to use as pattern — MUST ask, proactively suggest best candidate with reasoning), code reference file (SUT interface), comments on cases.

</IMPORTANT>

## Strategy Decision

Before writing cases, opus determines the approach:

| Codebase state | Strategy |
|---------------|----------|
| No test file for this SUT | New file. Use go-writer-test template |
| Test file exists, missing coverage | Add cases to existing table |
| Test file exists, cases need updating (new field, changed behavior) | Modify existing cases |
| Multiple behaviors in one function | One table per behavior, or one table with clear case grouping |

## Test Case Table

Each TDD cycle in the plan includes a table:

```
| # | Case name | Verifies | Hints |
|---|-----------|----------|-------|
| 1 | empty input | guard clause rejects before repo call | wantErr: ErrEmpty |
| 2 | repo error | error propagation without wrapping | before: repo.Get → assert.AnError |
| 3 | success | full pipeline: repo → transform → return | concrete args to repo.Get, assert on all result fields |
```

**Case order:** simple → complex → success LAST (go-writer-test TG-4).

## Hints Column

Hints are sonnet's implementation guide. Provide critical code where sonnet could guess wrong:

GOOD — hints with critical code:
```
| # | Case name | Verifies | Hints |
|---|-----------|----------|-------|
| 1 | empty input | validation rejects blank ID | wantErr: order.ErrEmptyID |
| 2 | not found | repo returns sentinel, usecase propagates | before: m.repo.EXPECT().Get(mock.Anything).Return(nil, repo.ErrNotFound); wantErr: repo.ErrNotFound |
| 3 | success | builds RefundResult from repo data | id := gofakeit.UUID(); expected := order.RefundResult{ID: id, Status: order.StatusPending}; before: m.repo.EXPECT().Get(id).Return(entity, nil); want: expected |
```

BAD — hints without actionable code:
```
| # | Case name | Verifies | Hints |
|---|-----------|----------|-------|
| 1 | empty input | validation | should return error |
| 2 | not found | error handling | mock repo to fail |
| 3 | success | happy path | should work |
```

## What to Include in Hints

Follow plan-orchestrator Critical Code rule: logic skeleton where sonnet could guess wrong.

- **Mock setup** — which method, which args (mock.Anything vs concrete), return values
- **Error types** — sentinel errors, assert.AnError for generic failures (TG-3)
- **Shared vars** — `id := gofakeit.UUID()`, `expected := Type{...}` (TF-1, TF-2)
- **Assertions** — exact fields to assert, assert.ErrorIs pattern
- **before signature** — `func(a args, m mockList)` or `func(m mockList)` (TT-3)

Sonnet follows these hints as patterns for the cases you described and extrapolates for similar cases.

## Existing Test Modification

When modifying existing tests, hints must reference current structure:

```
Strategy: ADD cases to TestService_Refund (internal/usecases/order/refund_test.go)

Existing cases: "empty input", "repo error", "success"
Add after "repo error":

| # | Case name | Verifies | Hints |
|---|-----------|----------|-------|
| 3 | partial refund exceeds total | business rule: refund amount <= order total | args: order with Total=100, refund Amount=200; wantErr: order.ErrRefundExceedsTotal |
| 4 | already refunded | idempotency guard | before: repo returns order with Status=Refunded; wantErr: order.ErrAlreadyRefunded |
```

## Integration

Invoked by plan-orchestrator during step 3 (writing-plans).

<IMPORTANT>

## Anchor

Most violated: TD-1 (planning artifact, not execution step), TD-3 (invoke go-writer-test before writing hints), TD-4 (ask user for reference test file, suggest best candidate).

</IMPORTANT>
