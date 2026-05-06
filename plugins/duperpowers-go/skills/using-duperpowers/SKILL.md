---
name: using-duperpowers
description: "Use at session start — establishes how duperpowers-go works, defines override triggers and skill index"
---

# Using Duperpowers

Duperpowers-go: standalone Go skills (writing, testing, review, verification) plus targeted overrides for superpowers defaults that conflict with this user's Go workflow.

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
| Writing Go code (*.go) | duperpowers-go:go-writer |
| Writing Go tests (*_test.go) | duperpowers-go:go-writer-test |
| Go code review | duperpowers-go:go-reviewer |
| Verify Go branch is shippable (build + format + tests + vet + dpcheck) | duperpowers-go:verify |
| Research codebase topics before planning | duperpowers-go:research |
| Notes in MIT outline format | duperpowers-go:mit-writer |
| Superpowers skill loaded | duperpowers-go:superpowers-overrides |

> Note: `gocheck` is a Task subagent invoked internally by `verify` (and used by other skills via the Task tool). It is NOT a Skill — never call `Skill(duperpowers-go:gocheck)`.

</IMPORTANT>
