---
name: plan-orchestrator
description: "MUST invoke when planning features, writing plans, or executing plans. Contains workflow, TDD, model selection, orchestration pipeline."
---

# Plan Orchestrator

<IMPORTANT>

## When This Skill Applies

ANY task that produces a plan or involves multi-step implementation. No size threshold.

| Rationalization | Reality |
|----------------|---------|
| "Too small for full workflow" | Small tasks produce the most convention violations |
| "I'll just write the code directly" | Without plan → no agent table → no test design → rework |

## Workflow

```
0. superpowers:brainstorming → spec
1. duperpowers-go:research (user confirms topic list before start)
   → research files + INDEX.md → suggest /compact
2. want-planning → re-read CLAUDE.md, invoke skills, report readiness
3. superpowers:writing-plans → plan with full test design inline + context fields
   → if research exists: read INDEX.md FIRST, use findings as ground truth,
     reference research file paths in files_read, do NOT re-explore researched topics
4. agent-assignment skill → DG → CO → agents → validation → PASS/FAIL
   → user reviews: plan + test designs + agent assignments
   If validation FAILs → orchestrator presents each finding WITH own assessment. Only user can approve.
5. plan-executability-review (opus subagent) → validate plan is solid for sonnet execution
   - Input: plan + agent table
   - Checks: exported/unexported consistency, import completeness,
     insertion point precision, sonnet executability (no "figure out" / "decide")
   - Output: PASS / FAIL + issues list
   - On FAIL: return to step 3 with issues, re-run steps 4-5
6. superpowers:subagent-driven-development OR superpowers:executing-plans → execute per agent table
   - Parallel agents: implement-only, do NOT commit (see Parallel Stage Commits)
   - Sequential barriers: make mock/gen between parallel stages only (see Sequential Barriers)
   - After each parallel stage: orchestrator makes compound commit
7. opus branch review (subagent, duperpowers-go:go-reviewer spec+quality) on full branch diff
   - CRIT/ERR → dispatch sonnet fix agent (file:line + description) → gocheck → re-review
   - Max 2 autofix iterations, then escalate to user (T3)
   - WARN/INFO only → report to user, done
8. execution diagnostics — orchestrator reviews full message history (planning + execution)
   - Output: plans/diagnostics-{ticket}.md
   - Content: what went wrong in pipeline, recommendations for workflow improvement
```

Go verification: delegate to duperpowers-go:gocheck agent.

</IMPORTANT>

## What & Why (required first section)

Plans MUST start with a "## What & Why" section before any steps.

### Problem
What's broken or missing. 1-3 sentences.

### Solution
Approach summary. 1-3 sentences. May reference packages/layers, but no code.

### What changes
Numbered list, max 7 items. Each item = one behavioral change + why.
Not files, not functions — what changes from the system's perspective.

### Out of scope
What this plan intentionally does NOT touch and why. Max 5 items.

Written in plain English. No agent metadata, no code samples.
Human must be able to review this section in under 60 seconds.

## Commits

Agent MUST propose commit messages in the plan. Format: `[TICKET-ID] краткое описание на русском`.

Example:
```
commit: [PROJ-42] реализует тесты CreateOrder
commit: [PROJ-42] реализует CreateOrder
```

User reviews and adjusts during plan review. If ticket ID unknown — ask user.

## Parallel Stage Commits

Parallel agents implement-only — they do NOT commit. After each parallel stage completes, orchestrator commits all changes in one compound commit.

Commit message format: `[TICKET-ID] stage N: краткое описание каждого deliverable`.

Example:
```
commit: [ACQ-19510] stage 2: order_view_update, refund_fiscal_receipt, payment_callback
```

Sequential agents (step 0, single-agent stages) commit normally per step.

## Sequential Barriers

Commands that regenerate shared files (`make mock`, `make gen`, any global code generation) are sequential barriers.

Rules:
- Sequential barrier MUST complete before any parallel stage that depends on its output
- Parallel agents MUST NOT run global generation commands
- Agent prompt for parallel steps: "Mocks already regenerated. Do NOT run make mock / make gen."
- If implementation changes require re-generation → checkpoint agent runs it between parallel stages

## Task Plan Format

Each step in the plan:
- **agent**: assigned by agent-assignment (e.g., sonnet-1, sonnet-2)
- **files_read**: primary input file paths the agent reads
- **files_write**: exact file paths the agent creates/modifies
- **what**: one-sentence deliverable
- **criteria**: how to verify (RED → GREEN for TDD steps)
- **code**: Go code or pseudo-Go for critical parts (see "Critical Code" below)
- **verify**: exact verification command
- **skills**: which skills the agent MUST invoke (see CLAUDE.md SUBAGENT SKILL INJECTION)
- **commit**: proposed commit message
- **context_needs**: what this step requires from prior steps (empty = independent)
- **context_shares**: what this step produces for later steps

Ambiguity in execution steps is a plan bug. "figure out", "decide", "choose", "explore" = opus failed to resolve during planning.

### Critical Code

Critical code = logic skeleton where sonnet could guess wrong. Provide pseudo/Go code for:

- **Signatures** — methods, constructors, interfaces, types
- **Conditions** — if/switch branching, guard clauses, error checks
- **Loops** — iterations with non-trivial logic (filtering, accumulation, break conditions)
- anything else where there's more than one reasonable implementation

Body inside branches, simple assignments, boilerplate — sonnet fills in.

## TDD in Plans

<CRITICAL>

Tests FIRST. No exceptions. MUST invoke `duperpowers-go:tdd-design` when writing test design in plan. No plan without test design. No test design without tdd-design skill.

| Rationalization | Reality |
|----------------|---------|
| "I know how to write test cases" | tdd-design enforces etalon reference, case table format, hints for sonnet. Skipping = sonnet guesses |
| "Test design is obvious for this feature" | Obvious to opus != executable by sonnet. tdd-design produces the artifact sonnet needs |

</CRITICAL>

Plan structure:
1. **Test design** (during planning, not execution) — opus invokes tdd-design, writes test case table with hints inline in plan. User reviews before execution.
2. **Tests + implementation** (single sonnet agent) — RED → GREEN cycle:
   - Write tests from plan's test design → run → verify RED
   - If tests pass on empty code → BLOCKED
   - Write implementation → run → verify GREEN
   - Cover error branches in the same pass
   - Sequential agents: commit tests first, then implementation separately
   - Parallel agents: no commits (orchestrator handles after stage)
3. **Checkpoint** (sonnet, duperpowers-go:gocheck)

Tests from plan's test design are the spec. Sonnet can fix test setup/mechanics but MUST NOT weaken assertions or change what tests verify. If tests conflict with implementation → BLOCKED, ask user.

| Rationalization | Reality |
|----------------|---------|
| "Tests need small adjustments to pass" | Tests are the spec. Fix implementation, not assertions. Setup fixes OK. Weakening conditions = BLOCKED |
| "This assertion is too strict" | Plan's test design was reviewed by user. Changing it = overriding user's decision |
If tests+impl > 300 lines total, split into two sonnet agents by scope.
Multi-step inline chains: limit 200 lines (see agent-assignment MA-2).

## Skill Assignment

| Step type | Skills | Verification |
|-----------|--------|-------------|
| Contracts (step 0) | go-writer | build passes |
| Tests + implementation | go-writer, go-writer-test | RED → GREEN |
| Implementation only | go-writer | build + run affected tests |
| Code review | go-reviewer (spec or quality) | — |
| Trivial (typo, config) | — | build |
| Checkpoint | gocheck (agent, not skill) | build + test-all + format + vet |

Verification commands go in the step's `verify` field. Agent runs the command, not a skill.

**Checkpoints in plan:** After each TDD cycle, plan MUST include a checkpoint with duperpowers-go:gocheck agent.

**Plan code samples:** Invoke duperpowers-go:go-writer first. Go conventions apply to plan examples, not just implementation.

## Model Selection

<CRITICAL>

Execution = sonnet. Opus for execution = user-approved exception.

</CRITICAL>

Planning is thinking. Execution is doing. All decisions resolved during planning with user.

| Task type | Model | Why |
|-----------|-------|-----|
| Test design | N/A (planning phase) | Opus writes in plan, user reviews before execution |
| Tests + implementation | sonnet | Plan has full test design + critical code |
| Contracts step (step 0) | sonnet | Mechanical: types, signatures, stubs from plan |
| Multi-step sequential (2-3 steps) | sonnet | Detailed plan = mechanical execution |
| gocheck / mechanical | sonnet | No decisions |
| Spec / quality review | sonnet + go-reviewer | Checklist-driven |
| Final review (full branch) | opus + go-reviewer | Architectural judgment |
| Debugging when sonnet stuck | opus | Root cause analysis |

## Agent Orchestration

### Pre-dispatch

For every agent before dispatching:

1. Read agent table — get agent ID, model, skills, receives, waits_for
2. Build skill injection prompt from agent's `skills` column (see CLAUDE.md SUBAGENT SKILL INJECTION)
3. Assess task clarity:
   - **Clear** (sonnet-safe): exact scope, one deliverable, concrete criteria
   - **Ambiguous**: "figure out", multiple approaches, vague criteria → ask user to refine
4. If agent writes tests → include test reference file from plan (user-provided etalon)
5. Assemble agent prompt — include:
   - "Receives" artifacts (paste content)
   - `files_read` + `files_write` paths
   - SUT interface/contract + function signatures
   - Full step text from plan

### Per-Agent Pipeline

```
0. Read agent table — do NOT re-analyze context_needs

1. Dispatch implementer (model + skills from agent table)
   - Skill injection FIRST
   - "Receives" artifacts + step text
   - If unclear → NEEDS_CONTEXT, does NOT guess

2. Run duperpowers-go:gocheck (sonnet) — build + format + test-all + vet
   - Fails → implementer fixes before review

3. Dispatch spec reviewer (sonnet + duperpowers-go:go-reviewer spec)
   - FAIL → implementer fixes → gocheck → re-review

4. Dispatch quality reviewer (sonnet + duperpowers-go:go-reviewer quality)
   - Only AFTER spec review PASS
   - FAIL → implementer fixes → gocheck → re-review

5. Mark agent complete → next per execution order
```

Light pipeline (CRUD, config, mechanical): steps 1-2 only.
Full pipeline: steps 1-4.

Parallel agents: no commit step in pipeline. Orchestrator handles compound commit after stage completes.
Sequential agents: commit normally at step 5.

### Post-Execution Pipeline

After ALL agents complete:

```
1. Dispatch opus branch reviewer (subagent)
   - Full branch diff vs base branch
   - duperpowers-go:go-reviewer spec + quality
   - Scope: entire changeset, not per-agent

2. If CRIT/ERR found:
   - Dispatch sonnet fix agent with exact file:line + issue description
   - Run duperpowers-go:gocheck
   - Re-dispatch opus reviewer
   - Max 2 iterations, then escalate to user (T3)

3. If WARN/INFO only: report to user, done

4. Execution diagnostics (orchestrator, not subagent)
   - Review full message history: planning decisions, agent execution, issues encountered
   - Write plans/diagnostics-{ticket}.md
   - Content: pipeline problems, agent failures, timing issues, workflow recommendations
```

### Error Escalation

| Tier | Condition | Action |
|------|-----------|--------|
| T1 | Compilation error, lint failure | Fix autonomously |
| T2 | Test failure from your changes | Fix, max 3 approaches. Same error x2 = BLOCKED |
| T3 | Test failure unrelated to your changes | Report to user, do not fix |
| T4 | Stuck after 3 attempts | Document attempts, STOP, wait for user |

After every fix: re-run verification.

**BLOCKED report format:**
```
STATUS: BLOCKED
STEP: [agent ID and step name]
ATTEMPTS: [what was tried, 1 line each]
DIAGNOSIS: [why it fails]
NEED: [what user input would unblock]
```

### Recovery

Agent API error/timeout → check `git diff`, run gocheck, retry (max 2), then STOP.
Agent fails repeatedly → STOP, report to user with diagnosis.

<IMPORTANT>

## Anchor — Most Violated

- Tests FIRST — TDD non-negotiable, test design inline in plan
- Tests are the spec — sonnet fixes implementation, not assertions
- Execution = sonnet. Opus = user-approved exception
- Every step is sonnet-ready: exact files, actual code, verify command
- Parallel agents don't commit — orchestrator compound commit after stage
- make mock / make gen = sequential barrier, never inside parallel stage
- BLOCKED after 3 failed attempts — document and STOP

</IMPORTANT>
