---
name: dispatch
description: "Use when transitioning a branch from L1.5 to L2 in the pseudocode-pipeline. Composite skill: generates plan.md, dispatches sonnet subagents in parallel (max 4) to resolve TODO: markers, invokes verify + review L2, manages the fix-loop."
---

# Dispatch

<IMPORTANT>

## Golden Rules

- **DSP-1.** Precondition: branch must be at L1.5. Invoke `duperpowers-go:verify L1.5` before any other action. If verdict ≠ PASS, STOP and report missing L1.5 guarantees. Do not generate plan.md, do not dispatch sonnet. User fixes L1.5 first (typically via `duperpowers-go:pseudocode-writer-test`).
- **DSP-2.** Generate `plan.md` as the L2 dispatch artifact per spec §8 structure: Summary (5-10 lines), Pointer map (layered by grpc-in / grpc-out / BL), DAG, Agent table, DoD checklist. `plan.md` is a pointer + coordination document — it does NOT duplicate logic that already lives in the pseudocode.
- **DSP-3.** Agent table = one sonnet agent per file (or a tight pair of files that must be edited together per layer coupling — typically prod + its `_test.go`). Max 4 concurrent agents (per `duperpowers-go:superpowers-overrides`). Parallel agents must NEVER touch overlapping files.
- **DSP-4.** Each sonnet subagent prompt MUST instruct it to load `duperpowers-go:go-writer` (before editing any `*.go`) and `duperpowers-go:go-writer-test` (before editing any `*_test.go`). Subagents resolve every `TODO:` in their assigned file(s) by replacing it with real code and deleting the marker. No leftover `TODO:` when the agent declares done.
- **DSP-5.** After the sonnet batch, invoke `duperpowers-go:verify L2`, then `duperpowers-go:review L2` (both mandatory; run serially so review sees a clean mechanical state). FAIL on either → fix-loop. L2 requires both PASS (spec §9 — mechanical + semantic).
- **DSP-6.** Fix-loop budget: max 2 iterations. Each: sonnet fix-agents → re-verify L2 → re-review (failing aspect only; full re-review if any fix touched > 1 file OR > 20 lines). After iter 2 still FAIL → STOP and escalate to user (BLOCKED) with the full failure trace.
- **DSP-7.** L2 is declared only when `verify L2` = PASS AND `review L2` = PASS. On declaration, `plan.md` is committed as the dispatch artifact alongside the code changes. Hand control back to user after commit.

## Anti-patterns

| Rationalization | Reality |
|-----------------|---------|
| "plan.md should describe each function's logic for the sonnet agents" | No (DSP-2). Logic is in the pseudocode — plan.md is pointers + DAG + DoD. Duplicating is stale-by-default. |
| "Run 8 sonnets at once since the files are small" | No (DSP-3). Max 4 parallel; beyond that Claude harness + reviewer synthesis degrades. Patience > speed. |
| "Two agents on one file — one does prod, one does test" | No (DSP-3). File overlap forbidden; race conditions + lost edits. One agent owns a file end-to-end. |
| "Subagent will figure out go-writer conventions without loading" | No (DSP-4). Skills must be loaded — conventions drift; sonnet needs the current rule set. |
| "Review is optional even at L2 if verify passes" | No (DSP-5). L2 review is mandatory per spec §9. Verify catches mechanical failures; review catches semantic ones. Both. |
| "5 fix-loop iterations — we'll converge eventually" | No (DSP-6). 2 iterations is the budget. Third attempt signals a design issue the user must address. |
| "Re-run ALL reviewers on every fix — safer" | No (DSP-6). Default is failing-aspect only. Full re-review only when fix touches > 1 file or > 20 lines. |

</IMPORTANT>

## Flow

```
L1.5 (pseudocode + test pseudocode, compiles, TODO: markers present)
   │
   │  DSP-1: verify L1.5 = PASS  (else STOP)
   │  DSP-2: generate plan.md
   │  DSP-3: agent table (sonnet-per-file, ≤ 4 parallel)
   │  DSP-4: dispatch sonnets (load go-writer / go-writer-test; resolve TODO:)
   │  DSP-5: verify L2 → review L2
   │  DSP-6: fix-loop on FAIL (≤ 2 iter → BLOCKED)
   ↓
L2 (no TODO: left, tests pass, review PASS, plan.md committed)
```

## `plan.md` Structure (spec §8)

Five sections, in order. Brevity > completeness — anything already in the pseudocode is NOT repeated here.

### 1. Summary (5-10 lines)

What this delivers and why. For human consumption before dispatch / review. Derived from:

- The branch diff at L1.5 (what files / funcs are touched)
- `TODO[group-tag]` group tags clustered by group (each group = a logical unit)
- Any accompanying issue / ticket reference

### 2. Pointer map (layered)

Navigation, not description. Bucket pointers by the three layers:

- **Edge-in** → grpc handlers; kafka consumers
- **Edge-out** → repos; grpc clients; kafka producers
- **BL** → `internal/uc/`, `internal/service/`, `internal/model/`

Map file paths to layers by convention (grpc handlers / kafka consumers = Edge-in; repos / kafka producers / grpc clients = Edge-out; uc/service/model = BL). Ambiguous → ask user.

Each pointer resolves to a file + symbol + line anchor, e.g.

```
- Edge-in  → internal/grpc/user_handler.go::Create (L42), Update (L78)
- Edge-out → internal/repo/user_repo.go::Save (L15), Delete (L33)
- BL       → internal/uc/user/create.go::UseCase.Handle (L12)
             internal/uc/user/update.go::UseCase.Handle (L9)
```

No re-description of what each function does — the file is the source of truth.

### 3. DAG (file-level)

Dependency graph at file granularity, derived from:

- Import edges in the diff (who imports whom)
- `TODO[group]` group tags (same group = logical unit; files in the same group ship together)
- Typical layer dependencies (Edge-in → BL → Edge-out)

Rendered ASCII:

```
internal/model/user.go        (leaf - no prereqs)
  ↓
internal/repo/user_repo.go    (depends on model)
  ↓
internal/uc/user/create.go    (depends on repo)
  ↓
internal/grpc/user_handler.go (depends on uc)
```

Independent subgraphs dispatch in parallel; dependent nodes serialize.

### 4. Agent table

One sonnet per file (or tight file pair per DSP-3). Columns: agent-id, files, skills, waits-for, commit-scope.

```
| Agent    | Files                                               | Skills                    | Waits for | Commit   |
|----------|-----------------------------------------------------|---------------------------|-----------|----------|
| sonnet-1 | internal/model/user.go, internal/model/user_test.go | go-writer, go-writer-test | -         | dispatch |
| sonnet-2 | internal/repo/user_repo.go, user_repo_test.go       | go-writer, go-writer-test | sonnet-1  | dispatch |
| sonnet-3 | internal/uc/user/create.go, create_test.go          | go-writer, go-writer-test | sonnet-2  | dispatch |
| sonnet-4 | internal/grpc/user_handler.go, user_handler_test.go | go-writer, go-writer-test | sonnet-3  | dispatch |
```

Max 4 concurrent. `Commit: dispatch` means the dispatch skill commits the combined stage, not the agent individually.

### 5. DoD checklist

Auto-extracted from `TODO[group-tag]` values + pipeline invariants. Short:

- [ ] All `TODO[get-user]` markers resolved in `internal/uc/user/*.go`
- [ ] All `TODO[user-audit]` markers resolved across model + repo
- [ ] `go test ./...` passes
- [ ] `duperpowers-go:review L2` verdict = PASS

## Subagent Dispatch

Mechanics: `superpowers:dispatching-parallel-agents`. Build batches from the DAG, max 4 concurrent (DSP-3). Each subagent prompt carries assigned files + its `plan.md` slice + DSP-4 skills/TODO instructions. On uncleared `TODO:`: agent self-retries once within the batch (independent of DSP-6's post-batch budget). Still uncleared → escalate to user (BLOCKED). Do not advance to verify until the batch is clean.

## Fix-Loop

Enters only on `verify L2` FAIL or `review L2` FAIL after the sonnet batch completes.

### Iteration (max 2)

1. Collect issues:
   - From verify FAIL: missing guarantees (e.g. leftover `TODO:` at file:line, gocheck errors, dpcheck findings)
   - From review FAIL: fix-loop directive from `duperpowers-go:review` (per REV-7 — file:line, rule IDs, failing aspect)
2. Dispatch sonnet fix-agent(s) — one per logical issue cluster. Fix-agent prompt includes issue details + source context + DSP-4 skills instruction.
3. After fix-agents return: invoke `duperpowers-go:verify L2`.
4. If verify PASS: invoke `duperpowers-go:review` — default re-reviews failing aspect only; full re-review if any fix touched > 1 file OR > 20 lines.
5. If verify PASS and review PASS → loop exits, L2 declared.

### Escalation

After iter 2 still FAIL: escalate to user (BLOCKED) with original verdicts + each iteration's fix-agent summary + currently-blocking issues. Past 2 iters = design issue; user must step in.

## Relationship to Other Skills

- `duperpowers-go:verify` — invoked as a gate (L1.5 precondition + L2 post-batch + in each fix-loop iteration).
- `duperpowers-go:review` — invoked once at L2 post-verify, then again per failing-aspect on fix-loop iterations.
- `duperpowers-go:go-writer` / `duperpowers-go:go-writer-test` — NOT loaded by this skill directly; this skill instructs subagents to load them (DSP-4).
- `duperpowers-go:pseudocode-writer` / `duperpowers-go:pseudocode-writer-test` — prior-transition skills; this skill takes over from their L1 → L1.5 output.
- `superpowers:dispatching-parallel-agents` — subagent dispatch pattern (mechanism only; no contract change).
- `superpowers:subagent-driven-development` — alternative pattern, not used by this skill; dispatch uses fan-out, not per-task sequential review.
- `duperpowers-go:superpowers-overrides` — enforces sonnet default (DSP-3 parallel cap of 4), Haiku-ban.

<IMPORTANT>

## Anchor

- **DSP-1.** Precondition `verify L1.5` = PASS. Not PASS → STOP.
- **DSP-2.** Generate plan.md per spec §8 — pointers + DAG + DoD, not logic duplication.
- **DSP-4.** Subagents load `go-writer` / `go-writer-test`; resolve every `TODO:` in-place.
- **DSP-5.** Post-batch: `verify L2` then `review L2`, both mandatory. FAIL → fix-loop.
- **DSP-6.** Fix-loop ≤ 2 iter, then BLOCKED.
- **DSP-7.** L2 = verify PASS AND review PASS; plan.md committed.

</IMPORTANT>
