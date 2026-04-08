---
name: research
description: "Use when opus needs to explore codebase topics before planning — produces structured research files + INDEX.md for clean-context planning"
---

# Research

<IMPORTANT>

## Golden Rules

**RS-1.** Research is a required phase. ALWAYS present topic list and wait for user OK before starting.
**RS-2.** Main opus runs research. May delegate to Explore agents. Writes findings to files.
**RS-3.** One file per topic + INDEX.md. Path: `plans/{task}/research/`.
**RS-4.** After research, tell user: "Research complete. Recommend `/compact` before planning."
**RS-5.** Opus writing the plan ALWAYS reads INDEX.md first. Loads topic file only when details needed. Do NOT re-explore topics already covered by research.

| Rationalization | Reality |
|----------------|---------|
| "I already know this codebase" | Knowledge != structured research. Without files opus greps again during planning — wasted tokens |
| "Research slows me down" | Shallow plan → rework during execution. Research saves time overall |
| "Brainstorming covered this" | Brainstorming = spec/requirements. Research = how code actually works under those requirements |
| "I'll put it all in the plan" | Plan context stuffed with raw code = context rot. Research files = compressed, reusable |
| "Codebase is small, I can explore during planning" | Planning and exploring simultaneously = context bloat. Research keeps planning context clean |

</IMPORTANT>

## What Is a Topic

A topic is any atomic body of knowledge the plan depends on.

Examples: how the event bus works, external service integration, data pipeline structure, delivery flow, existing test patterns, auth middleware chain, database schema for a feature.

## Process

**RS-6.** Steps 1-3 are MUST. Steps 4-6 are MUST per confirmed topic.

1. Read spec from brainstorming
2. Identify topics — list areas that need understanding before a plan can be written
3. Present topic list to user for confirmation
4. For each topic: explore (Explore agent / grep / read), write `plans/{task}/research/{topic}.md`
5. Write `plans/{task}/research/INDEX.md`
6. Tell user: "Research complete. Recommend `/compact` before planning."

**RS-7.** If exploration of a topic fails after 2 attempts, mark topic as UNRESOLVED in INDEX.md with diagnosis. Continue with remaining topics. Report unresolved topics to user before suggesting `/compact`.

## Research File

Opus structures findings freely. No rigid template.

SHOULD include:
- `file:line` references to key types, interfaces, functions
- How components connect to each other
- Existing tests and coverage gaps
- Constraints: breaking changes, cross-package dependencies, performance concerns
- Implications for the task — what this means for implementation

GOOD example:

```markdown
# Event Bus

## Scope
How events are published and consumed in the order service.

## Findings
- internal/events/bus.go:18 — Bus interface: Publish, Subscribe, Close
- internal/events/nats/bus.go:31 — NATS implementation, uses JetStream
- internal/order/service.go:92 — OrderCreated event published after repo.Save
- Events are protobuf-encoded (internal/events/proto/order.proto)

## Existing Tests
- internal/events/nats/bus_test.go — 8 tests, integration with testcontainers
- No tests for event serialization errors

## Constraints
- Bus interface is used in 3 packages — extending it = breaking change
- NATS connection is shared across services (singleton in cmd/server/main.go:45)

## Implications
- New event type: add to proto, regenerate, add handler — no interface change needed
- Test with testcontainers pattern from existing bus_test.go
```

## INDEX.md

**RS-8.** INDEX.md MUST contain for each topic: topic name, 1-line summary, path to research file, key project files.

Format is free. Opus structures as appropriate for the task.

GOOD example:

```markdown
# Research Index — ACQ-1234

## event-bus
How events are published and consumed in the order service
Research: plans/ACQ-1234/research/event-bus.md
Files: internal/events/bus.go, internal/events/nats/bus.go, internal/order/service.go, internal/events/proto/order.proto

## order-repository
Order persistence layer, PostgreSQL implementation, existing tests
Research: plans/ACQ-1234/research/order-repository.md
Files: internal/order/repo.go, internal/order/postgres/repo.go, internal/order/postgres/repo_test.go
```

## Integration

Research is phase 1 in plan-orchestrator workflow:

```
0. superpowers:brainstorming → spec
1. duperpowers-go:research (optional) → research files + INDEX.md → suggest /compact
2. want-planning → re-read CLAUDE.md, invoke skills
3. superpowers:writing-plans → plan (reads INDEX.md first)
```

After `/compact`, opus writing the plan starts with clean context. Research survives in files.

<IMPORTANT>

## Anchor

- **RS-1.** Research is optional. ALWAYS wait for user confirmation.
- **RS-2.** Main opus runs research. Writes findings to files.
- **RS-3.** One file per topic + INDEX.md. Path: `plans/{task}/research/`.
- **RS-4.** After research, suggest `/compact`.
- **RS-5.** Opus writing the plan reads INDEX.md first. Does not re-explore researched topics.
- **RS-7.** Topic fails after 2 attempts → UNRESOLVED in INDEX.md, report to user.

</IMPORTANT>
