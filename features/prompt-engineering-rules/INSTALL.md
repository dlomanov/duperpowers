---
name: prompt-engineering-rules
description: Reference skill for writing/editing CLAUDE.md, SKILL.md, and AI instruction files.
dependencies: []
platform: [all]
provides:
  skills: [prompt-engineering-rules]
---

# prompt-engineering-rules

A reference skill: rules for writing and editing CLAUDE.md, SKILL.md, and any AI
instruction files, sorted by measured impact. No scripts, no agents, no hooks.

## Install / update / remove

Follow the generic protocol in the repo-root `INSTALL.md`. Specifics:

- **provides** only `skills/prompt-engineering-rules` → symlinked to
  `~/.claude/skills/prompt-engineering-rules`.
- No dependencies, no hooks - nothing to wire, no dispatcher needed.
- **installed?** `~/.claude/features/prompt-engineering-rules` exists.

Project-scoped alternative: instead of `~/.claude/skills/`, the user may symlink the
skill into a project's `.claude/skills/` if they want it only for one repo.
