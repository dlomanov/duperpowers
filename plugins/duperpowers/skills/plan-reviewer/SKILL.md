---
name: plan-reviewer
description: "Validate implementation plan structure, agent assignments, TDD compliance, and step sufficiency. Structured PASS/FAIL verdicts with step references."
---

# Plan Reviewer

<IMPORTANT>

## Reviewer Rules

**RV-1.** Review the plan as written — do not propose new features or steps.
**RV-2.** Every ☠️ CRIT / 💥 ERR references a concrete step (e.g., "step 3").
**RV-3.** Uncertain => 👀 WARN, not 💥 ERR.
**RV-4.** Zero ☠️ CRIT + zero 💥 ERR => ✅ PASS.
**RV-5.** STOP and report if plan file is missing, empty, or has zero parseable steps.
**RV-6.** ALWAYS check all 4 categories: structural (ST), agent assignment (AG), TDD (TD), sufficiency (SF).

</IMPORTANT>

## Input

Plan document with:
- Steps (scope, what, criteria, skills, context_needs, context_shares, stage, commit)
- Agent assignment table (agent ID, model, steps, waits for, receives, skills)
- Execution order

If agent assignment is missing => 💥 ERR (run agent-assignment skill first).
If test design steps have no test cases listed => 💥 ERR (test design must be concrete before review).

## Checks

Four categories. Each check has a stable ID.

### Structural (ST)

**ST-1. DAG validity.** `context_needs` references MUST form a directed acyclic graph. Cycle => ☠️ CRIT.

**ST-2. No orphans.** Every step referenced in `context_needs` MUST exist. Missing step => ☠️ CRIT.

**ST-3. Single deliverable.** Each step MUST have exactly one `what`. Multiple deliverables => 💥 ERR (split the step).

**ST-4. Context fields present.** Every step MUST declare `context_needs` + `context_shares`. Missing => 💥 ERR.

**ST-5. Stage assigned.** Every step MUST have `stage: pre-implementation | implementation`. Missing => 💥 ERR.

**ST-6. No file conflicts.** Steps on different agents MUST NOT write the same file. Conflict => ☠️ CRIT.

### Agent Assignment (AG)

**AG-1. Shared context on same agent.** Steps that need accumulated context (not just artifacts) from a prior step MUST run on the same agent. Separate agents for shared-context steps => 💥 ERR.

Bright-line test: can the orchestrator capture what's needed by reading 1-2 files and pasting into the prompt? Yes => artifact (separate OK). No => accumulated (same agent required).

GOOD — accumulated context recognized:
```
Step 2: Storage write path
  context_shares: [UpdateV2 mutation patterns for step 3]

Step 3: Storage read path enrichment
  context_needs: [step 2: UpdateV2 file flow, Order().Copy() behavior]

=> accumulated (WHY code was written, not just WHAT it produces)
=> opus-1: steps 2-3 (inline chain) ✅
```

BAD — accumulated context split:
```
=> opus-1: step 2, sonnet-1: step 3 (step 3 loses behavioral understanding)
```

GOOD — artifact transfer split:
```
Step 2: Test implementation
  context_shares: [test contracts for step 3]

Step 3: Implementation
  context_needs: [step 2: test file contracts]

=> artifact (orchestrator reads create_test.go, pastes signatures)
=> opus-2: step 2, sonnet-1: step 3 ✅
```

**AG-2. Independent steps on separate agents.** Steps with empty `context_needs` NOT referenced by a chained step MUST be separate agents. Bundled independent steps => 👀 WARN.

**AG-3. Multi-step agents use opus.** Agent running 2-3 steps MUST be opus. Sonnet multi-step => 💥 ERR.

**AG-4. Max 3 steps per agent.** Agent with 4+ steps => 💥 ERR.

**AG-5. Agent IDs unique.** Duplicate agent IDs => ☠️ CRIT.

**AG-6. Execution order valid.** `waits_for` column MUST be consistent with context_needs DAG. Agent waits for non-existent agent => ☠️ CRIT.

**AG-7. Parallel safety.** Parallel agents MUST NOT write overlapping files. Overlap => ☠️ CRIT.

**AG-8. Mixed incoming edges.** When a step has both artifact AND accumulated incoming edges, it MUST be chained with the accumulated-context upstream. Artifact from other upstream passed in prompt. Missing chain => 💥 ERR.

| Rationalization | Reality |
|----------------|---------|
| "All steps are related, one agent is simpler" | Related scope != shared context. Independent steps get fresh agents (AG-2) |
| "4 steps is close enough to 3" | Context degrades after 3 — pattern bleed, convention drift (AG-4) |
| "Sonnet is faster for this chain" | Multi-step requires accumulated understanding — opus only (AG-3) |

### TDD (TD)

Verify compliance with plan-orchestrator "TDD in Plans" section. These checks are the mechanical validation:

**TD-1. Test design exists.** Every implementation step MUST have a preceding test design step (stage: pre-implementation). Missing test design => ☠️ CRIT.

**TD-2. Order preserved.** test design => test implementation => implementation => coverage hardening. Out of order => ☠️ CRIT.

**TD-3. Test design is pre-implementation.** All test design steps MUST have `stage: pre-implementation`. Wrong stage => 💥 ERR.

**TD-4. Test skills assigned.** Every test step (design, implementation, hardening) MUST include `duperpowers-go:go-writer-test` in skills. Missing => 💥 ERR.

**TD-5. Commit messages present.** Every step MUST have a commit message (not `[user fills in]` or blank). Missing => 💥 ERR.

### Sufficiency (SF)

**SF-1. Sonnet steps are concrete.** Sonnet steps MUST have: exact scope (file paths), one deliverable, concrete criteria. "Figure out" / "decide how" in sonnet step => 💥 ERR.

**SF-2. Opus steps require judgment.** Opus steps that are purely mechanical (rename, config change) => 👀 WARN (sonnet is sufficient).

**SF-3. Skills match step type.** Verify against plan-orchestrator "Skill Assignment" table. Missing required skill => 💥 ERR.

**SF-4. Checkpoints placed.** After each TDD cycle a duperpowers-go:gocheck checkpoint MUST exist. Missing checkpoint => 👀 WARN.

**SF-5. Scope defined.** Every step MUST have concrete `scope` (package path or file paths). Vague scope ("the codebase", "relevant files") => 💥 ERR.

**SF-6. API claims verifiable.** Function signatures, type names, methods in the plan SHOULD be checkable against code or `go doc`. Unverified API claims => 👀 WARN.

GOOD — concrete sonnet step:
```
Step 3: Implementation
  stage: implementation
  agent: sonnet-1
  scope: internal/usecases/order/create.go
  what: implement CreateOrder to pass all tests from step 2
  criteria: all tests from step 2 pass (green phase)
  skills: go-writer, verify
```

BAD — vague sonnet step:
```
Step 3: Implementation
  stage: implementation
  agent: sonnet-1
  scope: internal/usecases/order/
  what: figure out how to implement order creation
  criteria: works correctly
  skills: go-writer
```

## Output

Same format as duperpowers-go:go-reviewer. Every ☠️ CRIT / 💥 ERR MUST include step reference + fix.

```
MODE: plan-review
SUMMARY: 1-2 sentences proving you understood the plan's goal
VERDICT: ✅ PASS | ❌ FAIL
SCORE: 1-100

ISSUES:

CRIT1☠️ (RULE-ID) description => step N
  what is wrong
  fix: how to fix

ERR1💥 (RULE-ID) description => step N
  what is wrong
  fix: how to fix

WARN1👀 (RULE-ID) observation => step N

NOTES: (optional, ✅ PASS only, max 2)
```

Severity: ☠️ CRIT / 💥 ERR => ❌ FAIL. 👀 WARN only => ✅ PASS. Score: see duperpowers-go:go-reviewer.

<IMPORTANT>

## Self-Check (Anchor)

Before outputting verdict:
- SUMMARY proves you understood the plan's goal (not generic filler)
- Reviewed ALL steps, not just first few
- Every ☠️ CRIT / 💥 ERR has addressable code + rule ID + step reference + fix (RV-2)
- Checked all 4 categories: ST, AG, TD, SF (RV-6)
- No flags on things outside the plan (RV-1)
- VERDICT matches: >=1 CRIT or ERR = ❌ FAIL, else ✅ PASS (RV-4)
- SCORE consistent: 0 issues => 95+, WARNs only => 70-94, any ERR/CRIT => <70

</IMPORTANT>
