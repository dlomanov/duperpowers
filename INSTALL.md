# Install Duperpowers Features

> **You are an AI agent.** A user pasted this file (or a prompt pointing at it) to install one
> or more *features* from this repo into their `~/.claude/`. Follow the protocol below exactly.
> **Always ask `y/n` before each install/update/remove and before pulling in dependencies.**

A **feature** is a self-contained bundle of skills + agents + scripts + hooks, logically grouped,
with its own `features/<name>/INSTALL.md`. This file is the index + the generic protocol; each
feature's `INSTALL.md` only adds feature-specific notes on top of this protocol.

---

## Feature index

| Feature | Depends on | What it gives | INSTALL.md |
|---------|-----------|---------------|------------|
| `session-state` | - | `kv.sh` - per-session key/value store (`~/.claude/session_state/*.state`) | `features/session-state/INSTALL.md` |
| `context` | `session-state` | Cross-session memory: WAL log, summaries, recall, precompact (skills + agents + hooks) | `features/context/INSTALL.md` |
| `prompt-engineering-rules` | - | Reference skill for writing CLAUDE.md / SKILL.md / AI instruction files | `features/prompt-engineering-rules/INSTALL.md` |
| `mit-writer` | - | MIT-outline hierarchical notes skill | `features/mit-writer/INSTALL.md` |

To present choices to the user: show this table (feature + one-line "what it gives"), ask which to
install, then for each chosen feature read its `INSTALL.md` and run the protocol.

---

## Feature INSTALL.md frontmatter

Every `features/<name>/INSTALL.md` starts with:

```yaml
---
name: context
description: Cross-session memory - WAL log, summaries, recall.
dependencies: [session-state]      # other features that must be installed first ([] if none)
platform: [claude-code]            # or [all]
provides:
  skills:  [session-context, recall-context, precompact]   # dirs under features/<name>/skills/
  agents:  [context-reader, wal-compactor, wal-verifier]   # files under features/<name>/agents/
  scripts: [logwriter.sh]                                   # files under features/<name>/scripts/
  hooks:   [SessionStart, UserPromptSubmit]                 # files features/<name>/hooks/<Event>.sh
---
```

`provides` is the manifest the protocol links/unlinks. Omit empty keys.

---

## Layout in the checkout

```
features/<name>/
  INSTALL.md
  skills/<skill>/SKILL.md
  agents/<agent>.md
  scripts/<script>.sh
  hooks/<Event>.sh          # emits PLAIN TEXT (its additionalContext), NOT wrapped JSON
```

## Layout once installed (in ~/.claude)

```
~/.claude/features/<name>           # registry entry: symlink to checkout OR a copy (user choice)
~/.claude/skills/<skill>    -> features/<name>/skills/<skill>     (symlink)
~/.claude/agents/<agent>.md -> features/<name>/agents/<agent>.md  (symlink)
~/.claude/scripts/<s>.sh    -> features/<name>/scripts/<s>.sh     (symlink)
~/.claude/hooks/<Event>.d/<name>.sh -> features/<name>/hooks/<Event>.sh (symlink)
~/.claude/hooks/feature-hooks.sh    # dispatcher, installed once
```

Always symlink the leaf items **into the registry entry** (`~/.claude/features/<name>/...`), so a
single `remove` of the registry entry + the leaf symlinks fully uninstalls - regardless of whether
the registry entry itself is a symlink (live) or a copy (portable).

---

## Protocol

### 0. INSTALLED? (check before anything)
`~/.claude/features/<name>` exists  →  installed. Report status; ask if user wants update/remove.

### 1. INSTALL `<name>`
1. Read `features/<name>/INSTALL.md` frontmatter.
2. **Dependencies:** for each in `dependencies` not yet installed → tell the user it's required,
   ask `y/n` to install it first, and if yes recurse into INSTALL for the dependency.
3. **Mode:** ask the user - `symlink` (default; needs this checkout to stay in place; `update` = `git pull`)
   or `copy` (portable; survives without the checkout, for copying into another machine/repo).
4. Create registry entry:
   - symlink: `ln -s "<checkout>/features/<name>" "$HOME/.claude/features/<name>"`
   - copy:    `cp -R "<checkout>/features/<name>" "$HOME/.claude/features/<name>"`
5. For each item in `provides`, create the leaf symlink (see layout). On conflict (the item
   already exists in `~/.claude/...`), ask the user `Conflict at <path> - overwrite? [y/n]`;
   never overwrite silently.
6. **Hooks:** for each event in `provides.hooks`:
   - `mkdir -p "$HOME/.claude/hooks/<Event>.d"`
   - symlink `features/<name>/hooks/<Event>.sh` → `~/.claude/hooks/<Event>.d/<name>.sh`
   - ensure the dispatcher is wired (step 7).
7. **Dispatcher (once, idempotent):**
   - if `~/.claude/hooks/feature-hooks.sh` absent → install it from `features/_lib/feature-hooks.sh`
     (shared mechanism infra, not owned by any single feature). It runs every script in
     `~/.claude/hooks/<Event>.d/`, collects each one's stdout, and emits a single merged
     `{hookSpecificOutput:{hookEventName, additionalContext}}`.
   - ensure `settings.json` has, for each used `<Event>`, exactly one hook entry calling
     `"$HOME/.claude/hooks/feature-hooks.sh" <Event>`. Add if missing; never duplicate.
8. Confirm what was linked (file:line list) so the user can revert.

### 2. UPDATE `<name>`
- symlink mode: `git -C "<checkout>" pull` (everything is live; nothing to re-link).
- copy mode: re-`cp -R` the feature dir into the registry entry, then re-create leaf symlinks.

### 3. REMOVE `<name>`
1. **Dependents:** if any installed feature lists `<name>` in its `dependencies` → warn, ask `y/n`.
2. Remove every leaf symlink this feature created (skills/agents/scripts/`<Event>.d/<name>.sh`).
3. Remove `~/.claude/features/<name>`.
4. Leave the dispatcher and any user data (`~/.claude/session_state/*`) in place; ask `y/n` before
   deleting stored data.

---

## Personal preferences (optional)

The repo also ships `templates/claude-md-snippet.md`, the author's optional personal-preferences
snippet. It is **not** a feature - no install protocol, no symlink, no registry entry. To use it,
the user simply copies its contents and manually appends/adapts them in `~/.claude/CLAUDE.md`.

---

## Notes
- All user-facing prompts and messages are in English.
- This protocol writes only under `~/.claude/`. Never touch system temp dirs.
- Feature hook scripts run via a symlink in `<Event>.d/`, so they MUST resolve sibling
  scripts from `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/scripts/`, never from their own
  `$0`/`BASH_SOURCE` dir (that points at `<Event>.d/`, not `scripts/`).
- Idempotent: re-running INSTALL on an installed feature is a no-op + status report.
- Hooks are Claude Code only; on other platforms skip `provides.hooks`.
