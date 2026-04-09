---
name: want-executing
description: "Focus recovery - re-reads CLAUDE.md and execution skills when context has drifted before or during execution"
user_invocable: true
---

<CRITICAL>
YOU MUST complete all 3 steps BEFORE dispatching agents. No exceptions.
</CRITICAL>

## Why

CLAUDE.md rules lose priority as conversation grows. Execution is where violations happen - wrong model, skipped reviews, forgotten barriers.

## Steps

**Step 1 - DISCOVER.** Read CLAUDE.md with Read tool (NEVER from memory). Find everything related to:
- model selection (opus/sonnet), execution rules
- agent dispatch, agent table format
- parallel agents, sequential barriers
- commits in parallel stages, compound commits
- skill injection into subagents
- verification, gocheck, checkpoints
- post-execution review, branch review, diagnostics

**Step 2 - STUDY.** Invoke each skill via Skill tool. ALWAYS invoke all six: `duperpowers-go:plan-orchestrator`, `duperpowers-go:agent-assignment`, `duperpowers-go:go-writer`, `duperpowers-go:go-writer-test`, `duperpowers-go:go-reviewer`, `duperpowers-go:superpowers-overrides`.

**Step 3 - REPORT.** Announce to user:
- **Rules:** key execution rules you will follow
- **Agent table:** confirm plan has agent table with execution order
- **Pipeline tasks:** confirm pipeline phase tasks exist (steps 5-7), create if missing
- **Post-execution:** confirm you will run opus branch review (go-reviewer spec+quality on full branch diff) and write execution diagnostics after ALL agents complete
