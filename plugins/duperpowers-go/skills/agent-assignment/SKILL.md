---
name: agent-assignment
description: "MUST invoke after writing a plan (step 3 in workflow). Builds dependency graph, optimizes for parallelism, assigns agents, validates plan. Produces execution-ready artifacts."
---

# Agent Assignment

<IMPORTANT>

## Core Rules

**AA-1.** ALWAYS produce all 3 artifacts under `## Agent Assignment`: dependency graph, agent table, execution order.
**AA-2.** Orchestrator dispatches agents ONLY by reading the agent table.
**AA-3.** Prefer separate agents over inline chains. Fresh context + skill injection > accumulated context.
**AA-4.** STOP if plan has no `context_needs`/`context_shares` — run writing-plans first.
**AA-5.** STOP and ask user if an edge cannot be classified after applying the heuristic (CT).
**AA-6.** Annotate EACH task in the plan body with `**agent:** {agent-id}`.

</IMPORTANT>

## Input

Plan document with steps per plan-orchestrator Task Plan Format: `files_read`, `files_write`, `what`, `criteria`, `code`, `verify`, `skills`, `commit`, `context_needs`, `context_shares`.

## Algorithm

### Step 1. Build Dependency Graph (DG)

Read `context_needs` for every step. Create directed edges. Verify DAG — cycle => STOP, report to user.

**DG-1. Sequential barriers.** Steps containing global generation commands (`make mock`, `make gen`, or any command that regenerates shared files) MUST be sequential barrier nodes. All parallel steps that depend on generated output MUST wait for the barrier to complete. A barrier step cannot be placed inside a parallel stage.

### Step 2. Classify Context Transfer (CT)

For each edge:

**CT-1. Artifact** — downstream needs a discrete output (file, type, signature). Orchestrator captures it by reading 1-2 files.

**CT-2. Accumulated** — downstream needs understanding of WHY prior code was written (mutations, behavioral quirks, interplay). Cannot be captured by pasting files.

Heuristic: can you transfer the context by pasting file content into the prompt? Yes → CT-1. No → CT-2. Unclear → STOP, ask user.

### Step 3. Contract Extraction (CO)

Optimizes the plan for parallel execution. Analyzes the dependency graph for sequential chains where steps share types/contracts. Extracts shared contracts into step 0, rewrites dependencies so implementation steps depend only on step 0 and run in parallel.

**CO-1. Detect.** Sequential chains of 3+ steps with dependencies through types, struct fields, method signatures, sentinel errors, DAO fields.

**CO-2. Extract.** Add step 0 (contracts) to the plan:
- New/modified fields in DTO/domain/event structs
- Method signatures (empty body or `panic("not implemented")`)
- Sentinel errors, DAO fields
- Verify: `make build` passes

**CO-3. Rewrite dependencies.** Update `context_needs` to reference step 0. Recalculate DG edges.

**CO-4. Auto vs approval.**
- **Auto** (all conditions): chain 3+, ALL dependencies through types/signatures, after extraction ALL steps parallel
- **Approval** (any): mixed dependencies, some steps still sequential after extraction, unclear contract boundary

Auto: apply, note in output. Approval: show extraction, ask user.

**CO-5.** Implementation steps MUST NOT modify contracts from step 0. Need a new field → BLOCKED.

CO does NOT apply when: chain < 3 steps, dependencies through logic, contracts already in codebase.

### Step 4. Group Steps into Agents (GR)

**GR-1.** CT-2 accumulated => both steps on ONE agent (inline chain).
**GR-2.** CT-1 artifact => separate agents.
**GR-3.** Max 3 steps per agent. Chain of 4+ => split at the weakest link.
**GR-4.** Independent steps => separate agents.
**GR-5.** When in doubt CT-1 vs CT-2 => default to separate (AA-3).
**GR-6.** Mixed incoming (artifact + accumulated) => chain with accumulated upstream. Artifact passed in prompt.
**GR-7.** Checkpoint (gocheck) => always separate sonnet agent.
**GR-8.** Parallel agents implement-only — do NOT commit. Orchestrator makes compound commit after each parallel stage completes.

| Rationalization | Reality |
|----------------|---------|
| "All steps are related, run inline" | Related scope != shared context. Independent steps get fresh agents |
| "More steps per agent = faster" | After 3 steps context degrades — rework > fresh agent startup |

### Step 5. Assign Models (MA)

<CRITICAL>

Default is sonnet. Opus for execution = user-approved exception.

</CRITICAL>

**MA-1.** Default model is sonnet.
**MA-2.** Multi-step sonnet (2-3 inline steps) requires: full code in plan per step, same package or 2-3 files, total < 200 lines, verification command per step.
**MA-3.** Opus only for: final review, debugging, architectural decisions. Requires user approval during planning.
**MA-4.** Checkpoint / gocheck => sonnet.
**MA-5.** Test design is a planning artifact. Test design assigned to an agent => ERR.

### Step 6. Assign Agent IDs (AI)

Convention: `{model}-{sequential_number}`. Numbers global, sequential by execution order.

### Step 7. Validate Plan (VL)

Final validation before presenting to user. Check all categories:

**Structural:**
- VL-1. DAG valid (no cycles) => CRIT
- VL-2. No orphan references in `context_needs` => CRIT
- VL-3. Single deliverable per step => ERR
- VL-4. `context_needs` + `context_shares` present on every step => ERR
- VL-5. No file conflicts between parallel agents => CRIT

**Agent Assignment:**
- VL-6. CT-2 accumulated edges on same agent => ERR if split
- VL-7. Independent steps on separate agents => WARN if bundled
- VL-8. Multi-step sonnet has full code + same package or 2-3 files + < 200 lines => ERR if not
- VL-9. Max 3 steps per agent => ERR
- VL-10. Agent IDs unique => CRIT
- VL-11. `waits_for` consistent with DG => CRIT
- VL-12. Parallel agents don't write overlapping files => CRIT

**TDD:**
- VL-13. Test design exists in plan (inline AAA cases) for every implementation step => CRIT
- VL-14. Tests+impl steps include RED/GREEN verification => ERR
- VL-15. Test design as execution step (not test code) => ERR
- VL-16. Test steps include `go-writer-test` in skills => ERR
- VL-17. Commit messages present => ERR

**Sufficiency:**
- VL-18. Sonnet steps have: files_read, files_write, code, verify. Ambiguity language => ERR
- VL-19. Opus step without justification => WARN
- VL-20. Skills match plan-orchestrator Skill Assignment table => ERR
- VL-21. Checkpoints after each TDD cycle => WARN
- VL-22. Contract step 0 files not written by implementation steps => CRIT

**Parallel Execution:**
- VL-23. Parallel agents do not contain `make mock` / `make gen` / global generation => CRIT
- VL-24. Parallel agents do not commit (GR-8) — commit field empty or "orchestrator" => ERR

**Severity:** CRIT/ERR => FAIL. WARN only => PASS. Present findings with own assessment — user decides.

**Verdict format:**
```
VALIDATION: PASS | FAIL
FINDINGS:
  CRIT: [VL-ID] description => step N
  ERR: [VL-ID] description => step N
  WARN: [VL-ID] observation => step N
```

GOOD — sonnet-ready step:
```
Step 1: Tests + implementation for CreateOrder
  agent: sonnet-1
  files_read: internal/domain/order/order.go
  files_write: internal/usecases/order/create_test.go, internal/usecases/order/create.go
  what: write tests from plan test design, verify RED, implement CreateOrder, verify GREEN
  criteria: RED phase (tests fail) → GREEN phase (all tests pass)
  skills: go-writer, go-writer-test
```

BAD — ambiguous step:
```
Step 1: Implementation
  agent: sonnet-1
  scope: internal/usecases/order/
  what: figure out how to implement order creation
  criteria: works correctly
```

## Output

Append to plan under `## Agent Assignment`:
1. **Dependency graph** — ASCII with edges, CT classifications, agent boundaries
2. **Agent table** — columns: Agent, Model, Steps, Stage, Waits for, Receives, Skills
3. **Execution order** — parallel groups, checkpoints
4. **Validation verdict** — PASS/FAIL with findings

Max 4 concurrent agents. Checkpoints after logical groups.

For worked examples, read `agent-assignment-examples.md` in this skill directory.

## Integration

Runs as step 2 in plan-orchestrator workflow:
```
1. writing-plans => plan with steps + context fields
2. agent-assignment => this skill (DG → CO → GR → MA → AI → VL)
→ user reviews
3. plan-executability-review (opus subagent) => sonnet executability validation
4. execute per agent table
```

<IMPORTANT>

## Anchor

- All 3 artifacts + validation verdict present (AA-1)
- Every step in exactly one agent
- Every edge has CT-1/CT-2 classification
- CO applied where chain 3+ with type-only dependencies
- Default sonnet. Opus = user-approved exception (MA-1, MA-3)
- Test design is planning artifact, not agent step (MA-5)
- Validation covers: structural, agent assignment, TDD, sufficiency, parallel execution (VL)
- Could not classify an edge => asked user (AA-5)
- Global generation (make mock/gen) = sequential barrier in DG (DG-1)
- Parallel agents implement-only, no commits (GR-8, VL-24)

</IMPORTANT>
