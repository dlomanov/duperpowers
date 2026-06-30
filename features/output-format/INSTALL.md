---
name: output-format
description: Topdown "thought island" chat-output style - reference skill + a per-turn nudge hook.
dependencies: []
platform: [claude-code]
provides:
  skills:  [output-format]
  agents:  []
  scripts: []
  hooks:   [UserPromptSubmit]
---

# output-format

A personal chat-output style: responses built like code - a short high-signal thesis on
top, indented "child" lines elaborating it ("thought islands"). The skill carries the
rules + a large `examples/` gallery (good/bad, socratic, diagrams, and raw MIT 6.824
lecture notes as the structural model). The hook reminds the agent, every turn, to reply
using the skill.

## Install / update / remove

Follow the generic protocol in the repo-root `INSTALL.md`. Specifics:

- **skills:** the `output-format` skill dir (including its `examples/` subtree) →
  `~/.claude/skills/output-format`.
- **hooks:** `hooks/UserPromptSubmit.sh` → symlinked into
  `~/.claude/hooks/UserPromptSubmit.d/output-format.sh`. It emits PLAIN TEXT
  (its additionalContext, the line `Reply using the output-format skill.`); the
  **dispatcher** (`features/_lib/feature-hooks.sh`) wraps and merges it. Ensure the
  dispatcher is installed once and wired in `settings.json` per the protocol.
- **installed?** `~/.claude/features/output-format` exists.

## No dependencies

The hook has no siblings to resolve and uses no `kv.sh` - it is a single `printf`. Nothing
else is required.

## Verify after install

```sh
test -e ~/.claude/skills/output-format/SKILL.md && echo skill-ok
~/.claude/hooks/UserPromptSubmit.d/output-format.sh   # prints: Reply using the output-format skill.
```

Full smoke: start a new session, send any prompt, and confirm the UserPromptSubmit hook's
`additionalContext` carries the reminder line.

## Note

The hook is an unconditional per-turn nudge - it fires on every prompt. If you want it
quieter (every N turns), that would need `session-state` + a counter; this
feature deliberately stays dependency-free.
