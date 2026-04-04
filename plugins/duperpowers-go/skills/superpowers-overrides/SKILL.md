---
name: superpowers-overrides
description: "MUST invoke when any superpowers skill loads. Overrides superpowers defaults."
---

# Superpowers Overrides

These override superpowers:subagent-driven-development AND superpowers:executing-plans Integration sections.

<IMPORTANT>

## Override Table

| Superpowers instruction | Action |
|------------------------|--------|
| "Use the least powerful model" | NEVER follow. Follow plan-orchestrator Model Selection. Default is sonnet for all execution. |
| "Use opus for complex tasks" | NEVER follow. Complexity is resolved during planning. Execution is mechanical — sonnet. |
| "superpowers:test-driven-development" | NEVER follow during plan execution. Test design is a planning artifact (tdd-design). Sonnet implements from plan's test design. |
| "superpowers:using-git-worktrees — REQUIRED" | NEVER auto-use. Only when user explicitly requests. |
| "superpowers:dispatching-parallel-agents" | ALLOWED when steps do not share files, max 4 agents. |

</IMPORTANT>
