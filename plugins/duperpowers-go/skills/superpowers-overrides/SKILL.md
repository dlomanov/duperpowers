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
| "superpowers:test-driven-development" | NEVER auto-follow. Test-first is a user choice, not a default. If user explicitly opts in, use it; otherwise write code first, tests on demand. |
| "superpowers:using-git-worktrees — REQUIRED" | NEVER auto-use. Only when user explicitly requests. |
| "superpowers:dispatching-parallel-agents" | ALLOWED for research / independent exploration when steps do not share files; default cap 4. |
| "superpowers:verification-before-completion" on Go code | Route through `duperpowers-go:verify` instead of running ad-hoc `go build`/`go test` shell commands. |
| "superpowers:requesting-code-review" on Go code | Compose with `duperpowers-go:go-reviewer` (spec or quality mode). |

</IMPORTANT>
