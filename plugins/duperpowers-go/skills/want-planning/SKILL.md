---
name: want-planning
description: "Focus recovery - re-reads CLAUDE.md and planning skills when context has drifted in long sessions"
user_invocable: true
---

<CRITICAL>
YOU MUST complete all 3 steps BEFORE entering plan writing. No exceptions.
</CRITICAL>

## Why

CLAUDE.md rules lose priority as conversation grows.

## Steps

**Step 1 - DISCOVER.** Read CLAUDE.md with Read tool (NEVER from memory). Find everything related to:
- planning, plan structure, plan format
- TDD, test-first, test design
- model selection (opus/sonnet)
- skill injection into subagents
- verification, checkpoints
- commits in plans, user involvement

**Step 2 - STUDY.** Invoke each skill via Skill tool. ALWAYS invoke all four: `duperpowers-go:plan-orchestrator`, `duperpowers-go:tdd-design`, `duperpowers-go:agent-assignment`, `duperpowers-go:superpowers-overrides`.

**Step 3 - REPORT.** Announce to user:
- **Rules:** key planning rules you will follow
- **Skills:** list of skills invoked and confirmed
- **Pipeline tasks:** confirm pipeline phase tasks exist (steps 0-4), create if missing
- **Artifacts:** confirm brainstorm/spec exists or will be the first action; if research was done, confirm INDEX.md path
