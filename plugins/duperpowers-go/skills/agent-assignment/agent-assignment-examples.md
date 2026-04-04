# Agent Assignment — Worked Examples

## Example A: Simple TDD (independent steps)

```
Step 1: Tests + implementation for CreateOrder
  files_write: internal/usecases/order/create_test.go, internal/usecases/order/create.go
  context_needs: []
  context_shares: []

Step 2: Tests + implementation for converter
  files_write: internal/adapters/grpc/converter/order_test.go, internal/adapters/grpc/converter/order.go
  context_needs: []
  context_shares: []
```

**DG:** No edges. Independent.
**GR-4:** Separate agents.
**MA-1:** Sonnet (default).

```
| Agent    | Model  | Steps | Stage | Waits for          | Receives | Skills                   |
|----------|--------|-------|-------|--------------------|----------|--------------------------|
| sonnet-1 | sonnet | 1     | impl  | —                  | —        | go-writer, go-writer-test|
| sonnet-2 | sonnet | 2     | impl  | —                  | —        | go-writer, go-writer-test|
| sonnet-3 | sonnet | chk   | chk   | sonnet-1, sonnet-2 | —        | gocheck                  |

Parallel: sonnet-1, sonnet-2 => sonnet-3 (checkpoint)

VALIDATION: PASS
FINDINGS: (none)
```

## Example B: Contract Extraction (CO)

Input: 4 steps, sequential chain through shared types.

```
Step 1: Add RefundResult fields
  files_write: internal/domain/order/order.go
  context_needs: []
  context_shares: [RefundResult type for steps 2, 3, 4]

Step 2: Tests + impl for refund handler
  files_write: internal/usecases/order/refund.go, refund_test.go
  context_needs: [step 1: RefundResult type]
  context_shares: [handler events for step 3]

Step 3: Tests + impl for fiscal receipt
  files_write: internal/usecases/fiscal/receipt.go, receipt_test.go
  context_needs: [step 2: handler events]
  context_shares: []

Step 4: Tests + impl for GRPC converter
  files_write: internal/adapters/grpc/converter/refund.go, refund_test.go
  context_needs: [step 1: RefundResult type]
  context_shares: []
```

**DG:** 1→2, 2→3, 1→4.
**CT:** All through types/signatures → CT-1.
**CO-1:** Chain 1→2→3 is 3 steps, type-only. CO applies (auto).

After CO:

```
Step 0: Contracts — RefundResult, RefundRequested event, signatures
  verify: make build

Steps 1-3: each depends only on step 0
```

```
                  step 1 [sonnet-2]
                ↗
step 0 ──CT-1──→ step 2 [sonnet-3]    checkpoint [sonnet-5]
[sonnet-1]      ↘
                  step 3 [sonnet-4]

| Agent    | Model  | Steps | Stage | Waits for                    | Receives               | Skills                   |
|----------|--------|-------|-------|------------------------------|------------------------|--------------------------|
| sonnet-1 | sonnet | 0     | impl  | —                            | —                      | go-writer                |
| sonnet-2 | sonnet | 1     | impl  | sonnet-1                     | contracts (file paths) | go-writer, go-writer-test|
| sonnet-3 | sonnet | 2     | impl  | sonnet-1                     | contracts (file paths) | go-writer, go-writer-test|
| sonnet-4 | sonnet | 3     | impl  | sonnet-1                     | contracts (file paths) | go-writer, go-writer-test|
| sonnet-5 | sonnet | chk   | chk   | sonnet-2, sonnet-3, sonnet-4 | —                      | gocheck                  |

Sequential: sonnet-1
Parallel: sonnet-2, sonnet-3, sonnet-4 => sonnet-5 (checkpoint)
```

## Example C: Accumulated context (CT-2, inline chain)

```
Step 1: Implement storage write path (UpdateV2 mutations)
  files_write: internal/storage/order/write.go
  context_needs: []
  context_shares: [UpdateV2 mutation patterns for step 2]

Step 2: Implement storage read path enrichment
  files_write: internal/storage/order/read.go
  context_needs: [step 1: UpdateV2 file flow, Order().Copy() behavior]
  context_shares: []
```

**DG:** 1→2.
**CT:** "UpdateV2 file flow, Order().Copy() behavior" — needs understanding of WHY code was written, not just WHAT it produces. Can orchestrator capture this by pasting write.go? No — behavioral patterns, mutation interplay. → **CT-2 accumulated**.
**GR-1:** CT-2 → both steps on ONE agent (inline chain).
**MA-2:** Multi-step sonnet: 2 steps, same package, plan has full code → allowed.

```
step 1 ──CT-2──→ step 2
[    sonnet-1    ]

| Agent    | Model  | Steps | Stage | Waits for | Receives | Skills    |
|----------|--------|-------|-------|-----------|----------|-----------|
| sonnet-1 | sonnet | 1, 2  | impl  | —         | —        | go-writer |
| sonnet-2 | sonnet | chk   | chk   | sonnet-1  | —        | gocheck   |

Sequential: sonnet-1 => sonnet-2 (checkpoint)
```
