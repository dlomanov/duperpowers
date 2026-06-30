# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Duperpowers - a **features-only** repo. It is a collection of portable **features**: self-contained
bundles of skills + agents + scripts + hooks, installed directly into a user's `~/.claude/` via the
agent-facing repo-root `INSTALL.md`. Pure markdown/bash/JSON. There is no marketplace plugin, no
`plugin.json`, no `marketplace.json` - installation is by symlink/copy, not the plugin system.

### History

Earlier this repo was a marketplace plugin. First `duperpowers-go` - a Go development companion
(go-writer, go-reviewer, Go test skills, a `verify`/`gocheck` chain, `superpowers-overrides`). It was
then trimmed to `duperpowers` (the `using-duperpowers` session preamble + the `mit-writer` notes skill).
In this change the marketplace plugin was removed entirely and the repo refocused on the features
mechanism; `mit-writer` survived by becoming a feature. Earlier still, v0.0.x carried a
pseudocode-pipeline (L0/L1/L1.5/L2, sonnet fan-out via `dispatch`), cut in `0.1.0` (git tag
`pipeline-era`, commit `cec1706`). All plugin and Go history lives in git history.

## Testing changes

There is no `claude plugin install` anymore - features are installed via `INSTALL.md`.

Fastest check: run a feature's shipped test scripts.

```bash
bash features/session-state/scripts/test_kv.sh        # expect: 17 passed, 0 failed
```

Full-install verification: follow `INSTALL.md` against a throwaway `CLAUDE_CONFIG_DIR` pointed at a dir
**under `~/src/sand/docs/`** (never `mktemp -d` / system temp - banned in this workflow). Then confirm
symlinks resolve and hooks fire. For example:

```bash
mkdir -p ~/src/sand/docs/dp-test && CLAUDE_CONFIG_DIR=~/src/sand/docs/dp-test  # then run INSTALL.md
```

## Architecture

The features mechanism **is** the architecture.

- **`INSTALL.md` (repo root)** - the feature index + the generic install/update/remove/installed?
  protocol. It is agent-facing: a user pastes the file (or a URL to it) and the agent runs the
  protocol, asking `y/n` at each install/update/remove and before pulling in dependencies. Each
  `features/<name>/INSTALL.md` adds only feature-specific notes on top.
- **Per-feature frontmatter.** A feature's `INSTALL.md` frontmatter declares `name`, `description`,
  `dependencies`, `platform`, and a `provides` manifest (`skills`/`agents`/`scripts`/`hooks`). The
  protocol links/unlinks exactly what `provides` lists.
- **Install mode (user choice):** `symlink` (registry entry points at this checkout; `update` =
  `git pull`) or `copy` (portable - survives without the checkout, for moving into another
  machine/repo). Leaf items (skills/agents/scripts/hooks) are always symlinked **into** the registry
  entry `~/.claude/features/<name>/`, so removal is clean either way.
- **Hook dispatcher:** `settings.json` is touched once per event - one entry calling
  `feature-hooks.sh <Event>` (shipped from `features/_lib/feature-hooks.sh`). It runs every script in
  `~/.claude/hooks/<Event>.d/`, each emitting PLAIN TEXT, and merges into one
  `{hookSpecificOutput:{hookEventName, additionalContext}}` envelope. A feature drops a symlink to its
  hook script into `<Event>.d/`; remove = `rm`.
- **Sibling-resolution gotcha:** feature hook scripts run via a symlink in `<Event>.d/`, so they MUST
  resolve sibling scripts from `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/scripts/`, never from their own
  `$0`/`BASH_SOURCE` dir (which points at `<Event>.d/`, not `scripts/`).

Current features under `features/`:

| Feature | Deps | What it gives |
|---------|------|---------------|
| `session-state` | - | `kv.sh` - pure per-session key/value store (`~/.claude/session_state/*.state`) |
| `prompt-engineering-rules` | - | Reference skill for writing CLAUDE.md / SKILL.md / AI instruction files |
| `mit-writer` | - | MIT-outline hierarchical notes skill (user-facing) |
| `output-format` | - | Topdown "thought island" chat-output style (skill + per-turn nudge hook) |

## Conventions

### Adding a Feature

1. Create `features/<name>/INSTALL.md` with the frontmatter schema (`name`, `description`,
   `dependencies`, `platform`, `provides`) - see an existing feature's INSTALL.md.
2. Put leaf items under `features/<name>/{skills,agents,scripts,hooks}/`. Hook scripts emit PLAIN TEXT
   (the dispatcher wraps them) and resolve siblings from `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/scripts/`.
3. Add a row to the feature index table in `INSTALL.md`.
4. Add a row to the features table in README.md.
5. Ship test scripts in the feature dir (not linked) for post-install verification.

### Skill / file conventions

- Frontmatter: `name` (hyphens only) + `description` starting with a trigger phrase ("Use when...",
  "Use at...", "MUST invoke when...", or a terse project-noun phrase for reference skills such as
  `mit-writer`).
- Rule IDs are append-only (prefix per skill - see each skill's golden rules section). IDs only - rule
  **content** may be reframed in place; mention substantive reframes in the commit message so `git log`
  surfaces the pivot.
- `<IMPORTANT>` top + anchor bottom for golden rules.
    - Short skills (~50 lines or less) that are entirely an `<IMPORTANT>` block may omit the bottom
      anchor - the whole skill IS the anchor. Reference-style skills without rule lists (e.g.,
      `mit-writer`) may omit `<IMPORTANT>` entirely.
- Cross-references between skills use the bare skill name - once installed they live at
  `~/.claude/skills/<name>`. (No plugin prefix; there is no plugin.)

### Commits

- Never add `Co-Authored-By: Claude*` or AI attribution.
- Versioning is via git - there is no `plugin.json` to bump.
- Never stage: `.claude/*`, `task*.md`, `plans/*`, `docs/plans/*`, `docs/specs/*`. The user's home
  `~/.claude/CLAUDE.md` is off-limits too - the project `CLAUDE.md` at the repo root is tracked and
  edited normally.
