---
name: superpowers-overrides
description: "MUST invoke when any superpowers skill loads. Overrides superpowers defaults."
---

# Superpowers Overrides

<IMPORTANT>

## Override Table

| Superpowers instruction | Action |
|------------------------|--------|
| "Use the least powerful model" / "Use opus for complex tasks" | NEVER follow. Execution = sonnet. Planning resolves complexity before execution. |
| "superpowers:test-driven-development" | NEVER follow during plan execution. Test design is authored as test pseudocode (see duperpowers-go:pseudocode-writer-test) and resolved by sonnet at L1.5 → L2 dispatch. |
| "superpowers:using-git-worktrees — REQUIRED" | NEVER auto-use. Only when user explicitly requests. |
| "superpowers:dispatching-parallel-agents" | ALLOWED when steps do not share files, max 4 agents. |

</IMPORTANT>
