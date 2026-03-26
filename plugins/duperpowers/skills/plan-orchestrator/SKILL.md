---
name: plan-orchestrator
description: "MUST invoke when planning features, writing plans, or executing plans. Contains workflow, TDD, model selection, orchestration pipeline."
---

# Plan Orchestrator

<IMPORTANT>

## When This Skill Applies

ANY task that produces a plan or involves multi-step implementation. No size threshold — a 3-step fix and a 20-step feature both go through this workflow.

| Rationalization | Reality |
|----------------|---------|
| "The task is too small for full workflow" | Small tasks produce the most convention violations. Workflow catches them |
| "I already know what to do, no plan needed" | You knowing ≠ user approved. Plan = alignment artifact |
| "I'll just write the code directly" | Without plan → no agent table → no test design → rework |
| "I can skip agent-assignment for 2 steps" | 2-step plan still needs agent IDs for orchestrator dispatch |

## Workflow

```
0. superpowers:brainstorming → spec
1. want-planning → re-read CLAUDE.md, invoke this skill, report readiness
2. superpowers:writing-plans → plan with full test design inline + context fields + stages
3. agent-assignment skill → dependency graph + agent table + execution order
4. plan-reviewer skill → structural validation (PASS/FAIL)
→ user reviews: plan + test designs + agent assignments
   If plan-reviewer FAILs → orchestrator presents each finding WITH own assessment (agree/disagree + reasoning). Only user can approve execution.
5. superpowers:subagent-driven-development OR superpowers:executing-plans → execute per agent table
6. Final review: opus + duperpowers-go:go-reviewer on full branch diff vs origin/master
   (user handles commits, push, PR)
```

After each plan revision: invoke `diminishing-returns` skill.
Go verification: delegate to duperpowers-go:gocheck agent.

</IMPORTANT>

## When to Use Each Skill

| Trigger | Skill |
|---------|-------|
| Starting a new feature | superpowers:brainstorming |
| Need a structured plan | superpowers:writing-plans |
| After writing plan | agent-assignment |
| Before execution | plan-reviewer |
| Ready to execute | superpowers:subagent-driven-development OR executing-plans |
| Plan revision loop | diminishing-returns |
| Agent stuck on a bug | superpowers:systematic-debugging |
| Received review feedback | superpowers:receiving-code-review |
| Work done | duperpowers-go:go-reviewer on full branch diff (opus) |

## Commits

Agent MUST propose commit messages in the plan. Format: `[TICKET-ID] краткое описание на русском`.

Example:
```
commit: [PROJ-42] добавляет тест-дизайн для CreateOrder
commit: [PROJ-42] реализует тесты CreateOrder
commit: [PROJ-42] реализует CreateOrder
commit: [PROJ-42] добавляет тесты для непокрытых веток CreateOrder
```

User reviews and adjusts during plan review. If ticket ID unknown — ask user.

## Task Plan Format

Each step adds these fields to writing-plans format:
- **stage**: `pre-implementation` (text artifacts) | `implementation` (code)
- **agent**: assigned by agent-assignment (e.g., opus-1, sonnet-2) — encodes model
- **scope**: affected packages/files
- **what**: one-sentence deliverable
- **criteria**: how to verify
- **skills**: which skills the agent MUST invoke (see CLAUDE.md SUBAGENT SKILL INJECTION)
- **commit**: user fills in commit message
- **context_needs**: what this step requires from prior steps (empty = independent)
- **context_shares**: what this step produces for later steps

## TDD in Plans

<CRITICAL>

Tests are ALWAYS the FIRST step. No exceptions.

| Rationalization | Reality |
|----------------|---------|
| "The handler is trivial, tests aren't needed" | Trivial handlers produce the most regressions |
| "I'll add tests after implementation" | That's retrofitting, not TDD. Tests define the contract FIRST |
| "Tests slow down the plan" | Tests catch design issues before code exists. Cheaper than rework |
| "Only the main step needs tests, prep steps don't" | Every step producing Go code gets test steps |

</CRITICAL>

User participates in test design.

Plan structure:
1. **Test design** (opus, inline in plan) — full AAA design for each case (Arrange/Act/Assert), not just names. User reviews concrete contracts before any code.
2. **Test implementation** (opus) — write tests + stubs. Commit separately.
3. **Implementation** (per agent-assignment) — make tests pass. Commit.
4. **Coverage hardening** (opus) — find uncovered error branches, add test cases. Commit.

Written tests are never deleted. If tests conflict with implementation → STOP, ask user.

During planning, agent MUST ask user:
- Test reference file — MUST ask user, do NOT auto-pick neighboring tests (they may have bad patterns). User provides the etalon file, possibly from another package.
- Code reference file (interface/contract the SUT implements)
- User's comments on test cases

When implementing test designs → MUST invoke duperpowers-go:go-writer-test skill for Go test conventions (AAA, table tests, mock patterns, case order).

## Skill Assignment

| Step type | Skills | Verification |
|-----------|--------|-------------|
| Implementation | go-writer + verify | build + run affected tests |
| Tests | go-writer + go-writer-test + verify | build + run new tests (must fail before impl) |
| Code review | go-reviewer (spec or quality) | — |
| Plan review | plan-reviewer | — |
| Trivial (typo, comment, config) | verify only | build |
| Checkpoint (after logical group) | gocheck | build + test-all + format + vet |

verify = build + run affected tests (fast, after each step).
duperpowers-go:gocheck = build + test-all + format + vet (full, at checkpoints).

**Checkpoints in plan:** After each TDD cycle, plan MUST include a checkpoint with duperpowers-go:gocheck.

**Plan code samples:** Invoke duperpowers-go:go-writer first. Go conventions apply to plan examples, not just implementation.

## Model Selection

Core heuristic: **think = opus, do = sonnet.**

**think + do in one step is an anti-pattern.** Split it: "think" step (opus) produces spec, "do" step (sonnet) executes.

| Task type | Model | Why |
|-----------|-------|-----|
| Test design (listing cases) | opus | Requires understanding behavior |
| Writing tests | opus | Tests define correctness |
| Implementation with clear plan | sonnet | Plan has all decisions |
| duperpowers-go:gocheck (build/test/lint) | sonnet | Mechanical |
| Mechanical (rename, delete, config) | sonnet | No decisions needed |
| Spec review | sonnet + duperpowers-go:go-reviewer | Checklist-driven |
| Quality review | sonnet + duperpowers-go:go-reviewer | Checklist-driven |
| Final review (full branch) | opus + duperpowers-go:go-reviewer | Architectural judgment |
| Debugging when sonnet stuck | opus | Root cause analysis |

**Unclear spec → STOP.** Refine with user. Every step should be clear enough for sonnet.
**Ambiguous model choice → STOP.** Step is poorly defined. Ask user.
**Fallback:** Timeout/failure → retry same model, max 2 attempts, then STOP.

## Agent Orchestration

### Pre-dispatch

For every agent before dispatching:

1. Read agent table — get agent ID, model, skills, receives, waits_for
2. Build skill injection prompt from agent's `skills` column (see CLAUDE.md SUBAGENT SKILL INJECTION)
3. Assess task clarity:
   - **Clear** (sonnet-safe): exact scope, one deliverable, concrete criteria
   - **Ambiguous**: "figure out", multiple approaches, vague criteria → ask user to refine
4. If agent writes tests → include test reference file from plan (user-provided etalon)
5. Assemble init prompt context — MUST include:
   - "Receives" column artifacts (read files, paste content)
   - Exact file paths from step's `scope`
   - Interface/contract the SUT implements
   - Function signatures agent will call
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
   - FAIL → implementer fixes → duperpowers-go:gocheck → re-review

4. Dispatch quality reviewer (sonnet + duperpowers-go:go-reviewer quality)
   - Only AFTER spec review PASS
   - FAIL → implementer fixes → duperpowers-go:gocheck → re-review

5. Mark agent complete → next per execution order
```

Light pipeline (CRUD, config, mechanical): steps 1-2 only.
Full pipeline: steps 1-4.
Final opus review with duperpowers-go:go-reviewer on full branch diff after ALL agents.

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

Agent API error/timeout → check `git diff`, run duperpowers-go:gocheck, retry (max 2), then STOP.
Agent fails repeatedly → STOP, report to user with diagnosis.

<IMPORTANT>

## Anchor

- NO task is "too small" for this workflow — small tasks produce the most violations
- Test design is FULL AAA inline in plan — not abstract names
- Tests FIRST in every plan — TDD is non-negotiable
- think = opus, do = sonnet — mixing is an anti-pattern
- Orchestrator reads agent table, never re-analyzes context_needs
- STOP and report BLOCKED after 3 failed attempts
- Agent proposes commit messages in plan, user reviews

</IMPORTANT>
