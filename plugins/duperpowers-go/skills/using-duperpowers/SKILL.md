---
name: using-duperpowers
description: "Use at session start — establishes how duperpowers-go works, defines override triggers and skill index"
---

# Using Duperpowers

Duperpowers-go: Go development pipeline with planning, orchestration, TDD, and superpowers overrides.

<IMPORTANT>

## Priority

1. User instructions (CLAUDE.md) — highest
2. Duperpowers overrides — modify superpowers defaults where specified
3. Superpowers skills — general workflow
4. Default system prompt — lowest

## Override Trigger

MUST invoke `duperpowers-go:superpowers-overrides` when any superpowers skill loads. No exceptions.

| Rationalization | Reality |
|---------|---------|
| "I already loaded superpowers-overrides earlier" | Context may have been compressed. Load again |
| "This superpowers skill doesn't need overrides" | ALL superpowers skills get overrides |

## Skill Index

| Task | Invoke |
|------|--------|
| Planning features/tasks | duperpowers-go:plan-orchestrator |
| Research topics before planning | duperpowers-go:research |
| Writing test design in plan | duperpowers-go:tdd-design |
| Assigning agents + validating plan | duperpowers-go:agent-assignment |
| Superpowers skill loaded | duperpowers-go:superpowers-overrides |
| Writing Go code (*.go) | duperpowers-go:go-writer |
| Writing Go tests (*_test.go) | duperpowers-go:go-writer-test |
| Go code review | duperpowers-go:go-reviewer |
| Deep branch review | duperpowers-go:make-go-review |
| Go verification (low-level) | duperpowers-go:gocheck (agent) |
| Writing production pseudocode (L0 → L1) | duperpowers-go:pseudocode-writer |
| Verify pseudocode-pipeline level guarantees | duperpowers-go:verify |
| Notes in MIT outline format | duperpowers-go:mit-writer |
| Focus recovery before planning | duperpowers-go:want-planning |
| Focus recovery before execution | duperpowers-go:want-executing |

</IMPORTANT>
