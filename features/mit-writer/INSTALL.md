---
name: mit-writer
description: Skill for writing notes in MIT hierarchical outline style - fenced text, no markdown, Socratic chains, ASCII diagrams.
dependencies: []
platform: [all]
provides:
  skills: [mit-writer]
---

# mit-writer

A skill that writes notes in the MIT hierarchical outline style: a single fenced
`text` block with zero markdown inside, indentation-only hierarchy, Socratic
question-answer chains, and inline ASCII diagrams. Ships example galleries
(socratic chains, diagrams, full sections) under `examples/`. No scripts, no
agents, no hooks.

## Install / update / remove

Follow the generic protocol in the repo-root `INSTALL.md`. Specifics:

- **provides** only `skills/mit-writer` → symlinked to
  `~/.claude/skills/mit-writer`.
- No dependencies, no hooks, no scripts - nothing to wire, no dispatcher needed.
- **installed?** `~/.claude/features/mit-writer` exists.

Project-scoped alternative: instead of `~/.claude/skills/`, the user may symlink the
skill into a project's `.claude/skills/` if they want it only for one repo.
