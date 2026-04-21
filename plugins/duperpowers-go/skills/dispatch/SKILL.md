---
name: dispatch
description: "Use when transitioning a branch from L1.5 to L2 in the pseudocode-pipeline. Composite skill: generates plan.md as a dispatch artifact, dispatches sonnet subagents in parallel (max 4) to resolve TODO: markers, invokes duperpowers-go:verify L2 (mandatory), invokes duperpowers-go:review L2 (mandatory), and manages the fix-loop (max 2 iterations before T3 escalation). Precondition: branch at L1.5 — skill invokes duperpowers-go:verify L1.5 first and STOPs on FAIL."
---

# Dispatch

<IMPORTANT>

## Golden Rules

- **DSP-1.** Precondition: branch must be at L1.5. Invoke `duperpowers-go:verify L1.5` before any other action. If verdict ≠ PASS, STOP and report missing L1.5 guarantees. Do not generate plan.md, do not dispatch sonnet. User fixes L1.5 first (typically via `duperpowers-go:pseudocode-writer-test`).
- **DSP-2.** Generate `plan.md` as the L2 dispatch artifact per spec §8 structure: Summary (5-10 lines), Pointer map (layered by grpc-in / grpc-out / BL), DAG, Agent table, DoD checklist. `plan.md` is a pointer + coordination document — it does NOT duplicate logic that already lives in the pseudocode.
- **DSP-3.** Agent table = one sonnet agent per file (or a tight pair of files that must be edited together per layer coupling — typically prod + its `_test.go`). Max 4 concurrent agents (per `duperpowers-go:superpowers-overrides`). Parallel agents must NEVER touch overlapping files.
- **DSP-4.** Each sonnet subagent prompt MUST instruct it to load `duperpowers-go:go-writer` (before editing any `*.go`) and `duperpowers-go:go-writer-test` (before editing any `*_test.go`). Subagents resolve every `TODO:` in their assigned file(s) by replacing it with real code and deleting the marker. No leftover `TODO:` when the agent declares done.
- **DSP-5.** After the sonnet batch completes, invoke `duperpowers-go:verify L2` (mandatory). On FAIL — collect missing guarantees; proceed to fix-loop. Never declare L2 without verify PASS.
- **DSP-6.** After verify PASS, invoke `duperpowers-go:review L2` (mandatory). On FAIL — collect fix-loop directive; proceed to fix-loop. Review is mandatory at L2 per spec §9 — verify is mechanical, review is semantic, both required.
- **DSP-7.** Fix-loop budget: max 2 iterations (per verify or review failure cycle). Each iteration: dispatch sonnet fix-agent(s) per blocking issue, re-verify L2, re-review failing aspect only — UNLESS a single fix touched > 1 file OR > 20 lines (then re-review BOTH aspects). If the 2nd iteration still FAILs, STOP and T3-escalate to user with the full failure trace.
- **DSP-8.** L2 is declared only when `verify L2` = PASS AND `review L2` = PASS. On declaration, `plan.md` is committed as the dispatch artifact alongside the code changes. Hand control back to user after commit.

## Anti-patterns

| Rationalization | Reality |
|-----------------|---------|
| "User said L1.5 was green — skip verify L1.5" | No (DSP-1). Last-known-good state is not trustworthy after edits. The skill is the gate. |
| "plan.md should describe each function's logic for the sonnet agents" | No (DSP-2). Logic is in the pseudocode — plan.md is pointers + DAG + DoD. Duplicating is stale-by-default. |
| "Run 8 sonnets at once since the files are small" | No (DSP-3). Max 4 parallel; beyond that Claude harness + reviewer synthesis degrades. Patience > speed. |
| "Two agents on one file — one does prod, one does test" | No (DSP-3). File overlap forbidden; race conditions + lost edits. One agent owns a file end-to-end. |
| "Subagent will figure out go-writer conventions without loading" | No (DSP-4). Skills must be loaded — conventions drift; sonnet needs the current rule set. |
| "Skip verify L2 — sonnet declared done" | No (DSP-5). Every transition ends with verify(target_L). Sonnet self-report is not a guarantee. |
| "Review is optional even at L2 if verify passes" | No (DSP-6). L2 review is mandatory per spec §9. Verify catches mechanical failures; review catches semantic ones. Both. |
| "5 fix-loop iterations — we'll converge eventually" | No (DSP-7). 2 iterations is the budget. Third attempt = T3 escalation. Past 2 iters signals a design issue the user must address. |
| "Re-run ALL reviewers on every fix — safer" | No (DSP-7). Default is failing-aspect only. Full re-review only when fix touches > 1 file or > 20 lines — the threshold past which cross-aspect regressions become plausible. |
| "Skip committing plan.md — it's throwaway" | No (DSP-8). It's the dispatch artifact — audit trail for who touched what. Commits with the code. |

</IMPORTANT>

## Purpose

Composite skill that drives the L1.5 → L2 transition end-to-end. The only skill in the pipeline that orchestrates other agents — all other skills are single-actor (user or one sonnet / opus).

```
L1.5 (pseudocode + test pseudocode, compiles, TODO: markers present)
   │
   │  DSP-1: verify L1.5 = PASS  (else STOP)
   │  DSP-2: generate plan.md
   │  DSP-3: agent table (sonnet-per-file, ≤ 4 parallel)
   │  DSP-4: dispatch sonnets (load go-writer / go-writer-test; resolve TODO:)
   │  DSP-5: verify L2
   │  DSP-6: review L2
   │  DSP-7: fix-loop on FAIL (≤ 2 iter → T3 escalate)
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

- **Edge-in** → `internal/grpc/*.go` handlers; kafka consumers
- **Edge-out** → `internal/repo/*.go`; grpc clients; kafka producers
- **BL** (business logic) → `internal/uc/`, `internal/service/`, `internal/model/`

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

## Example plan.md (hypothetical branch)

```markdown
# plan.md - dispatch artifact (L1.5 → L2)

## Summary
Adds UserService.GetUser end-to-end: new BL use case, repo method,
grpc handler. Two TODO groups: `get-user` (happy path + error mapping),
`user-audit` (audit emission on fetch).

## Pointer map
- Edge-in  → internal/grpc/user_handler.go::GetUser (L41)
- Edge-out → internal/repo/user_repo.go::Get (L22)
- BL       → internal/uc/user/get.go::UseCase.Handle (L10)
             internal/model/user.go (types, no methods)

## DAG
internal/model/user.go
  ↓
internal/repo/user_repo.go
  ↓
internal/uc/user/get.go
  ↓
internal/grpc/user_handler.go

## Agent table
| Agent    | Files                                               | Skills                    | Waits for | Commit   |
|----------|-----------------------------------------------------|---------------------------|-----------|----------|
| sonnet-1 | internal/model/user.go, internal/model/user_test.go | go-writer, go-writer-test | -         | dispatch |
| sonnet-2 | internal/repo/user_repo.go, user_repo_test.go       | go-writer, go-writer-test | sonnet-1  | dispatch |
| sonnet-3 | internal/uc/user/get.go, get_test.go                | go-writer, go-writer-test | sonnet-2  | dispatch |
| sonnet-4 | internal/grpc/user_handler.go, user_handler_test.go | go-writer, go-writer-test | sonnet-3  | dispatch |

## DoD
- [ ] All `TODO[get-user]` resolved
- [ ] All `TODO[user-audit]` resolved
- [ ] `go test ./...` passes
- [ ] `duperpowers-go:review L2` = PASS
```

## Layer Detection Heuristic

From file path, map to layer. Follow the prefix pattern:

| Path pattern                              | Layer     |
|-------------------------------------------|-----------|
| `internal/grpc/*.go` handlers             | Edge-in   |
| kafka consumer implementations            | Edge-in   |
| `internal/repo/*.go`                      | Edge-out  |
| grpc clients (usually `internal/client/`) | Edge-out  |
| kafka producer implementations            | Edge-out  |
| `internal/uc/...`                         | BL        |
| `internal/service/...`                    | BL        |
| `internal/model/...`                      | BL        |

If the project uses different conventions, adapt at runtime — the layer is a semantic bucket, not a path enforcement. Ambiguous case → ask user.

## Subagent Dispatch

Dispatch mechanics follow `superpowers:dispatching-parallel-agents`. This skill does NOT define a new subagent framework — it describes the flow:

1. Read the agent table from `plan.md` — one entry per agent.
2. Build the parallel batches per the DAG (agents with the same `waits_for` dependency depth run in the same batch, capped at 4).
3. For each agent, craft a focused subagent prompt:
   - Assigned files (scope)
   - The relevant `plan.md` slice (summary + pointer-map row for this agent)
   - Explicit instruction: "Load `duperpowers-go:go-writer` before editing any `*.go`. Load `duperpowers-go:go-writer-test` before editing any `*_test.go`. Resolve every `TODO:` in assigned files by replacing it with real code and deleting the marker. Do NOT touch files outside your scope. Do NOT commit — dispatch commits the stage."
   - Expected output: "Report per file: which TODO: markers resolved, which remain (if any), file compiled clean, tests compiled clean."
4. Dispatch the batch. Wait for all agents to return before starting the next batch.
5. If any agent reports uncleared `TODO:` — that agent reruns once, or escalates to T3. Do not advance to verify until the batch is clean.

## Fix-Loop

Enters only on `verify L2` FAIL or `review L2` FAIL after the sonnet batch completes.

### Iteration (max 2)

1. Collect issues:
   - From verify FAIL: missing guarantees (e.g. leftover `TODO:` at file:line, gocheck errors, dpcheck findings)
   - From review FAIL: fix-loop directive from `duperpowers-go:review` (per REV-7 — file:line, rule IDs, failing aspect)
2. Dispatch sonnet fix-agent(s) — one per logical issue cluster. Fix-agent prompt includes:
   - Issue details (file:line + rule ID + aspect + hint)
   - The relevant source context
   - Same skills instruction (DSP-4)
3. After fix-agents return: invoke `duperpowers-go:verify L2`.
4. If verify PASS: invoke `duperpowers-go:review` — scope rule:
   - **Default:** re-review ONLY the failing aspect (cheaper, focused).
   - **Full re-review:** triggered if ANY fix touched > 1 file OR > 20 lines total. Rationale: broad fixes may introduce regressions in the other aspect.
5. If verify PASS and review PASS → loop exits, L2 declared.

### Escalation

After 2 failed iterations, STOP and T3-escalate to user with:

- Original verify / review verdicts
- Each iteration's fix-agents summary
- The currently-blocking issues

Do not start a 3rd iteration. Continuing past 2 signals a design issue that fix-agents cannot mechanically resolve — user needs to step in.

## Process

1. **Precondition.** Invoke `duperpowers-go:verify L1.5`. On FAIL → STOP, report missing guarantees, hand back to user. On PASS → continue.
2. **Plan.** Generate `plan.md` per spec §8 structure (this skill's §"plan.md Structure"). Write to branch root.
3. **Dispatch.** Read agent table; build parallel batches from DAG; dispatch sonnet batch(es). Each subagent loads go-writer / go-writer-test and resolves `TODO:` in-place (DSP-4). Wait for all to return.
4. **Verify.** Invoke `duperpowers-go:verify L2`. PASS → continue. FAIL → enter fix-loop.
5. **Review.** Invoke `duperpowers-go:review L2`. PASS → continue. FAIL → enter fix-loop.
6. **Fix-loop (conditional).** On any failure in step 4 or 5, run fix-loop iteration(s) per §"Fix-Loop". Max 2. If still FAIL after iter 2 → STOP, T3-escalate.
7. **Declare L2.** On all-PASS, commit `plan.md` alongside the code changes as the dispatch artifact (DSP-8). Hand control back to user.

## Open Items

- `plan.md` concrete generator details — this skill describes the *shape* and heuristics; Claude follows the shape at runtime. If empirical runs show the layered-map auto-bucketing mis-classifies a project's file layout, adapt per-project or ask the user for layer hints.
- Fix-loop iteration caps are blanket 2 (DSP-7). R8 §Risks flagged "per-aspect caps may differ" — revisit if real runs show aspect B mechanical fixes routinely converge in 1 iter while aspect A needs more. No change for M3.
- Subagent mechanism: this skill names `superpowers:dispatching-parallel-agents` as the reference pattern. If the Claude harness grows native parallel-Task support later, swap the mechanism without changing this skill's contract.

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
- **DSP-4.** Subagents load `go-writer` / `go-writer-test`; resolve every `TODO:` in-place.
- **DSP-5.** Post-batch `verify L2` mandatory.
- **DSP-6.** Post-verify `review L2` mandatory.
- **DSP-7.** Fix-loop ≤ 2 iter, then T3-escalate.
- **DSP-8.** L2 = verify PASS AND review PASS; plan.md committed.

</IMPORTANT>
