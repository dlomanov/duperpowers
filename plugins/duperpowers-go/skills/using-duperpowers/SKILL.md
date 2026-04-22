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
| Research topics before planning | duperpowers-go:research |
| Superpowers skill loaded | duperpowers-go:superpowers-overrides |
| Writing Go code (*.go) | duperpowers-go:go-writer |
| Writing Go tests (*_test.go) | duperpowers-go:go-writer-test |
| Go code review | duperpowers-go:go-reviewer |
| Go verification (low-level) | `duperpowers-go:gocheck` (Task agent — invoke via Task tool, not Skill) |
| Writing production pseudocode (L0 → L1) | duperpowers-go:pseudocode-writer |
| Writing test pseudocode (L1 → L1.5) | duperpowers-go:pseudocode-writer-test |
| Dispatch L1.5 → L2 (composite transition) | duperpowers-go:dispatch |
| Verify pseudocode-pipeline level guarantees | duperpowers-go:verify |
| Level-aware review (L0/L1/L1.5/L2) | duperpowers-go:review |
| Notes in MIT outline format | duperpowers-go:mit-writer |

</IMPORTANT>
