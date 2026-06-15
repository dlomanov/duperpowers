---
name: context
description: Cross-session memory - WAL log, summaries, recall, precompact (skills + agents + hooks).
dependencies: [session-state]
platform: [claude-code]
provides:
  skills:  [session-context, recall-context, precompact]
  agents:  [context-reader, wal-compactor, wal-verifier]
  scripts: [logwriter.sh]
  hooks:   [SessionStart, UserPromptSubmit]
---

# context

Persistent, cross-session memory for the agent. An append-only WAL per session
(`~/.claude/session_state/<sid>.wal`), cached summaries (`.sum`), and a precompact
path (`.ckpt`). The SessionStart hook restores prior context; the UserPromptSubmit
hook nudges the agent to flush a delta every N turns.

## Dependency

Depends on **session-state**: the UserPromptSubmit hook and the `precompact` skill use
`kv.sh` for the turn counter `context.turns_since_flush`. The install protocol must
install `session-state` first (it will ask before doing so).

## Install / update / remove

Follow the generic protocol in the repo-root `INSTALL.md`. Specifics:

- **scripts:** `logwriter.sh` → `~/.claude/scripts/logwriter.sh`.
- **agents:** the three `.md` files → `~/.claude/agents/`.
- **skills:** the three skill dirs → `~/.claude/skills/`.
- **hooks:** `hooks/SessionStart.sh` and `hooks/UserPromptSubmit.sh` → symlinked into
  `~/.claude/hooks/SessionStart.d/context.sh` and `~/.claude/hooks/UserPromptSubmit.d/context.sh`.
  These hook scripts emit PLAIN TEXT (their additionalContext); the **dispatcher**
  (`features/_lib/feature-hooks.sh`) wraps and merges. Ensure the dispatcher is installed
  once and wired in `settings.json` per the protocol.
- **sibling resolution:** the hook scripts find `logwriter.sh`/`kv.sh` via
  `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/scripts/` - NOT via their own dir (they run through
  a symlink in `<Event>.d/`). So `scripts/` must be installed at the config-dir root.
- **installed?** `~/.claude/features/context` exists.

## Verify after install

```sh
bash ~/.claude/features/context/scripts/test_logwriter.sh   # expect: Results: 27 passed, 0 failed
```

Full smoke: start a new session and confirm the SessionStart hook restores context, then
ask to recall something. `test_logwriter.sh` ships for verification; it is not linked.

## Data & cleanup

Stored under `~/.claude/session_state/` (`.wal`, `.sum`, `.state`, `.ckpt`). Remove leaves
this data in place by default; the protocol asks before deleting stored data.
