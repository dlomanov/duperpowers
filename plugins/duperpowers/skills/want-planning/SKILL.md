---
name: want-planning
description: "Use when transitioning to plan writing — after brainstorming, when task/spec is ready, or when user explicitly wants to start planning. Refreshes planning context from CLAUDE.md, studies relevant skills, reports readiness"
---

<CRITICAL>
YOU MUST complete all 3 steps BEFORE entering plan writing. No exceptions.
</CRITICAL>

## Why

CLAUDE.md rules lose priority as conversation grows.

## Steps

**Step 1 — DISCOVER.** Read CLAUDE.md with Read tool (NEVER from memory). Find everything related to:
- planning, plan structure, plan format
- TDD, test-first, test design
- model selection (opus/sonnet)
- skill injection into subagents
- verification, checkpoints
- commits in plans, user involvement

**Step 2 — STUDY.** Invoke each relevant skill via Skill tool. ALWAYS invoke `plan-orchestrator` — it contains the full planning workflow, TDD structure, model selection, and orchestration pipeline.

**Step 3 — REPORT.** Announce to user:
- **Rules:** key planning rules you will follow
- **Skills:** list of skills invoked and confirmed

## Anti-rationalization

| Rationalization | Reality |
|---------|---------|
| "I already read CLAUDE.md at session start" | Thousands of tokens ago. Re-read now |
| "I remember the planning rules" | Prove it — Step 3 exists for this |
| "I can skip straight to writing-plans" | writing-plans doesn't force CLAUDE.md re-read. This skill does |

<CRITICAL>
Re-read CLAUDE.md with Read tool. Announce rules. Enter plan writing. Every time. No shortcuts.
</CRITICAL>
