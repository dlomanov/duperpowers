---
name: agent-assignment
description: "MUST invoke after writing a plan (step 3 in workflow). Builds dependency graph, assigns numbered agents, produces execution order for orchestrator."
---

# Agent Assignment

<IMPORTANT>

## Core Rules

**AA-1.** ALWAYS produce all 3 artifacts and append them to the plan document under `## Agent Assignment`: dependency graph, agent table, execution order.
**AA-2.** Orchestrator dispatches agents ONLY by reading the agent table — never re-analyzes context_needs at execution time.
**AA-3.** ALWAYS prefer separate agents over inline chains. Fresh context + skill injection > accumulated context.
**AA-4.** STOP if plan has no `context_needs`/`context_shares` — run writing-plans first.
**AA-5.** STOP and ask user if an edge cannot be classified as artifact or accumulated after applying the bright-line test (CT-2).

</IMPORTANT>

## Input

Plan document where each step has:
- `context_needs`: what this step requires from prior steps (empty = independent)
- `context_shares`: what this step produces for later steps
- `stage`: pre-implementation | implementation
- `scope`: affected files/packages
- `skills`: required skills

## Algorithm

### Step 1. Build Dependency Graph (DG)

**DG-1.** Read `context_needs` for every step. Create directed edges.

```
step 1 (context_shares: [test cases for step 2])
step 2 (context_needs: [step 1: test cases], context_shares: [contracts for step 3])
step 3 (context_needs: [step 2: contracts])
step 4 (context_needs: [step 3: implementation])
step 5 (context_needs: [])

=> edges: 1->2, 2->3, 3->4
=> step 5 independent
```

**DG-2.** Verify DAG — no cycles. Cycle detected => STOP, report to user.

### Step 2. Classify Context Transfer (CT)

For each edge, classify what the downstream step actually needs:

**CT-1. Artifact transfer** — step needs a discrete output (text, file, signature). Upstream produces a file or list. Downstream reads it. No shared mental model needed.

**CT-2. Accumulated context** — step needs the upstream agent's working understanding (file mutations, behavioral quirks, interplay between components).

Bright-line test: can the orchestrator capture what's needed by reading 1-2 files and pasting content into the prompt?
- Yes => CT-1 artifact
- No => CT-2 accumulated
- Cannot decide => STOP, ask user (AA-5)

Heuristic: if the step needs to understand WHY prior code was written (not just WHAT it produces) => accumulated.

```
"receives approved test cases (text)"           => CT-1 artifact
"receives test file contracts (file path)"       => CT-1 artifact
"receives implementation file (file path)"       => CT-1 artifact
"needs UpdateV2 file flow + Order().Copy() behavior" => CT-2 accumulated
"needs understanding of how events propagate"        => CT-2 accumulated
```

### Step 3. Group Steps into Agents (GR)

Rules applied in priority order:

**GR-1. (MUST)** CT-2 accumulated edges => both steps on ONE agent (inline chain).

**GR-2. (MUST)** CT-1 artifact edges => separate agents. Orchestrator reads artifact, passes in prompt.

**GR-3. (MUST)** Max 3 steps per agent. Chain of 4+ accumulated edges => split at the weakest link (edge closest to artifact transfer).

**GR-4. (MUST)** Independent steps (no incoming/outgoing accumulated edges) => separate agent.

**GR-5. (SHOULD)** When in doubt about CT-1 vs CT-2 => default to separate (AA-3).

**GR-6. (MUST)** Mixed incoming edges — step has both artifact AND accumulated inputs => chain with the accumulated-context upstream. Artifact from other upstream passed in prompt.

**GR-7. (MUST)** Checkpoint steps (duperpowers-go:gocheck) => always separate sonnet agent. Waits for all agents in its logical group.

GOOD — accumulated context => chained:
```
context_needs: [step 2: UpdateV2 file flow, Order().Copy() behavior]
=> CT-2 (needs WHY, not just WHAT) => opus-1: steps 2-3 inline
```

BAD — accumulated context => split:
```
=> opus-1: step 2, sonnet-1: step 3 (step 3 loses behavioral understanding)
```

| Rationalization | Reality |
|----------------|---------|
| "Splitting adds overhead from skill injection" | Skill injection = 10 seconds. Pattern bleed fix = 10 minutes |
| "All steps are related, run inline" | Related scope != shared context. Independent tests MUST get fresh agents |
| "More steps per agent = faster" | After 3 steps context degrades — rework > fresh agent startup |
| "I'll figure out grouping during execution" | By execution time, accumulated context already biases the agent |
| "I can't tell if it's artifact or accumulated" | Apply bright-line test (CT-2). Still unclear => STOP, ask user (AA-5) |

### Step 4. Assign Models (MA)

Apply plan-orchestrator Model Selection rules. Additional assignment rules:

**MA-1. (MUST)** Multi-step agent (2-3 inline steps) => ALWAYS opus. Overrides individual step types — a chain of [implementation, implementation] becomes opus when chained.

**MA-2. (MUST)** Test design => opus (defines correctness contracts).

**MA-3. (MUST)** Test implementation => opus (tests are correctness).

**MA-4. (SHOULD)** Single step, clear spec => sonnet. All decisions already in plan.

**MA-5. (MUST)** Checkpoint / duperpowers-go:gocheck => sonnet. Mechanical.

### Step 5. Assign Agent IDs (AI)

**AI-1.** Convention: `{model}-{sequential_number}`. Numbers global across plan, sequential by execution order.

```
opus-1, opus-2, sonnet-1, opus-3, sonnet-2
```

## Output

ALWAYS produce all 3 artifacts (AA-1). Append to plan under `## Agent Assignment` heading:
1. **Dependency graph** — ASCII with step edges, CT classifications, agent boundaries (box inline chains)
2. **Agent table** — columns: Agent, Model, Steps, Stage, Waits for, Receives, Skills
3. **Execution order** — pre-impl first, then impl chains, parallel groups, checkpoints

Rules: pre-impl agents first, user reviews before impl starts, max 4 concurrent, checkpoints after logical groups.

## Worked Example

Input plan (5 steps):

```
Step 1: Test design for CreatePayout
  stage: pre-implementation
  scope: internal/usecases/payout/
  context_needs: []
  context_shares: [test case list for step 2]

Step 2: Test implementation
  stage: implementation
  scope: internal/usecases/payout/create_test.go
  context_needs: [step 1: approved test cases]
  context_shares: [test contracts for step 3]

Step 3: Implementation
  stage: implementation
  scope: internal/usecases/payout/create.go
  context_needs: [step 2: test file contracts]
  context_shares: [implementation for step 4]

Step 4: Coverage hardening
  stage: implementation
  scope: internal/usecases/payout/create_test.go
  context_needs: [step 3: implementation to review for uncovered branches]
  context_shares: []

Step 5: Converter tests (independent)
  stage: implementation
  scope: internal/adapters/grpc/converter/payout_test.go
  context_needs: []
  context_shares: []
```

**DG-1.** Edges: 1->2, 2->3, 3->4. Step 5 independent.

**CT classification:**
- 1->2: "approved test cases" => CT-1 artifact (text list, pasteable)
- 2->3: "test file contracts" => CT-1 artifact (read _test.go, paste signatures)
- 3->4: "implementation to review for uncovered branches" => CT-1 artifact (read create.go)

All edges are CT-1 artifact => all steps can be separate agents.

**What if edge 2->3 were CT-2?** If step 3 needed behavioral understanding of test structure (not just signatures), edge 2->3 becomes CT-2 accumulated. Then GR-1 applies: opus-2 runs steps 2-3 inline, sonnet-1 disappears, opus-3 waits for opus-2 instead. Table changes: `opus-2 | opus | 2,3 | impl | opus-1 | ...`.

**GR rules:** GR-2 applies (all artifact), GR-4 applies (step 5 independent). No chains needed.

**MA rules:** MA-2 (test design => opus), MA-3 (test impl => opus), MA-4 (impl clear spec => sonnet), MA-3 (coverage = tests => opus), MA-4 (converter tests clear spec but tests => opus per MA-3).

**Result:**

```
  step 1 ──CT-1──→ step 2 ──CT-1──→ step 3 ──CT-1──→ step 4
  [opus-1]          [opus-2]         [sonnet-1]        [opus-3]

  step 5                            checkpoint          checkpoint
  [opus-4]                          [sonnet-2]          [sonnet-3]

| Agent    | Model  | Steps | Stage      | Waits for | Receives                      | Skills                           |
|----------|--------|-------|------------|-----------|-------------------------------|----------------------------------|
| opus-1   | opus   | 1     | pre-impl   | —         | —                             | go-writer, go-writer-test        |
| opus-2   | opus   | 2     | impl       | opus-1    | test cases (text from opus-1) | go-writer, go-writer-test, verify|
| sonnet-1 | sonnet | 3     | impl       | opus-2    | contracts (file: _test.go)    | go-writer, verify                |
| opus-3   | opus   | 4     | impl       | sonnet-1  | impl (file: create.go)        | go-writer, go-writer-test, verify|
| opus-4   | opus   | 5     | impl       | —         | —                             | go-writer, go-writer-test, verify|
| sonnet-2 | sonnet | chk   | checkpoint | opus-3    | —                             | gocheck                          |
| sonnet-3 | sonnet | chk   | checkpoint | opus-4    | —                             | gocheck                          |

Pre-implementation:
  1. opus-1 (step 1: test design)
  => user reviews

Implementation:
  Sequential: opus-2 => sonnet-1 => opus-3 => sonnet-2 (checkpoint)
  Parallel: opus-4 => sonnet-3 (checkpoint)
```

## Integration

Runs as step 3 in plan-orchestrator workflow:
```
2. writing-plans => plan with steps + context fields
3. agent-assignment => this skill
4. plan-reviewer => validates plan + assignments
→ user reviews
5. execute per agent table
```

<IMPORTANT>

## Self-Check (Anchor)

Before outputting:
- All 3 artifacts present: graph, table, execution order (AA-1)
- Every step appears in exactly one agent
- Every edge has explicit CT-1 / CT-2 classification
- No agent has 4+ steps (GR-3)
- Multi-step agents use opus (MA-1)
- Independent steps on separate agents (GR-4)
- Checkpoint steps are separate sonnet agents (GR-7)
- Pre-implementation agents ordered before implementation
- Agent IDs are unique, sequential, follow `{model}-{N}` convention (AI-1)
- `waits_for` column consistent with dependency graph (DG-1)
- Could not classify an edge => asked user, not guessed (AA-5)

</IMPORTANT>
