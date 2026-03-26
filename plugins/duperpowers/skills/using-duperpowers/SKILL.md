---
name: using-duperpowers
description: "Use at session start — establishes how duperpowers complements superpowers, defines override triggers and anchor rules"
---

# Using Duperpowers

Duperpowers extends superpowers with planning orchestration, validation, and workflow overrides. It does NOT replace superpowers — it adds structure on top.

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<IMPORTANT>

## Relationship with Superpowers

Superpowers' 1% rule already covers duperpowers skills — they appear in the shared skill list. This skill adds context that superpowers cannot provide: override triggers, anchor rules, and operational protocols.

**Priority:**
1. User instructions (CLAUDE.md) — highest
2. Duperpowers overrides — modify superpowers defaults where specified
3. Superpowers skills — general workflow
4. Default system prompt — lowest

## Override Trigger

MUST invoke `duperpowers:superpowers-overrides` when any superpowers skill loads.

This is non-negotiable. The override modifies superpowers defaults:
- Model selection: think=opus, do=sonnet. NEVER follow "use least powerful model"
- Git worktrees: NEVER auto-use, only when user explicitly requests
- Parallel agents: ALLOWED when steps do not share files, max 4

| Thought | Reality |
|---------|---------|
| "I already loaded superpowers-overrides earlier" | Load it again. Context may have been compressed. |
| "This superpowers skill doesn't need overrides" | ALL superpowers skills get overrides. No exceptions. |
| "The override is overkill for this task" | Small tasks produce the most convention violations. |

## Anchor Rules

When these tasks arise, invoke the corresponding duperpowers skill:

| Task | Invoke |
|------|--------|
| Planning features/tasks | duperpowers:plan-orchestrator |
| Transitioning to plan writing | duperpowers:want-planning (before writing-plans) |
| Reviewing a plan | duperpowers:plan-reviewer |
| Assigning agents to plan steps | duperpowers:agent-assignment |
| Validating approach before coding | duperpowers:gatekeeper |
| After code changes | duperpowers:verify |
| Plan revision loop (3+ rounds) | duperpowers:diminishing-returns |

These work alongside superpowers skills, not instead of them.

## Subagent Skill Injection

When dispatching subagents via superpowers:subagent-driven-development or superpowers:executing-plans:

**Implementer prompt MUST include BEFORE task description:**
```
Before starting work, invoke the Skill tool for each skill listed below.
Skills: [list from step's skills field]
Announce: "Loaded skills: [list]".
If unclear — STOP and report NEEDS_CONTEXT. Do not guess.
```

**Reviewer prompt MUST include BEFORE review instructions:**
```
Code review: invoke duperpowers-go:go-reviewer (mode: spec or quality).
Plan review: invoke duperpowers:plan-reviewer instead.
Announce loaded skill.
```

## Error Escalation

| Tier | Condition | Action |
|------|-----------|--------|
| T1 | Compilation/lint error | Fix autonomously |
| T2 | Test failure from your changes | Fix, max 3 approaches. Same error x2 = BLOCKED |
| T3 | Unrelated test failure | Report to user, do not fix |
| T4 | Stuck after 3 attempts | Document attempts, STOP, wait for user |

After every fix (T1/T2): re-run full verification before marking complete.

## Agent Recovery

When an agent fails repeatedly:
1. Do NOT retry the same scope — decompose into smaller substeps
2. Use sonnet for mechanical edits and build/test
3. Before relaunching, verify what the failed agent completed via `git diff`
4. Resume from the first incomplete substep only

</IMPORTANT>
