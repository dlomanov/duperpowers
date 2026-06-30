# Duperpowers

A collection of **portable features** for Claude Code / Cursor - bundles of skills + agents +
scripts + hooks you install straight into your `~/.claude/` (or a project's `.claude/`). Pure
markdown/bash/JSON. No marketplace plugin.

## Install

Works in both Claude Code and Cursor. Tell your AI:

```
Fetch and follow instructions from https://raw.githubusercontent.com/dlomanov/duperpowers/main/INSTALL.md
```

The agent shows the feature list and walks you through install/update/remove, asking `y/n` at each
step. Each feature installs either as a **symlink** to this checkout (live; `update` = `git pull`)
or as a **copy** (portable - survives without the checkout, for moving onto another machine/repo).

## Features

| Feature | Depends on | What it gives |
|---------|-----------|---------------|
| `session-state` | - | `kv.sh` - per-session key/value store |
| `prompt-engineering-rules` | - | Reference skill for writing CLAUDE.md / SKILL.md / AI instruction files |
| `mit-writer` | - | MIT-outline hierarchical notes skill |
| `output-format` | - | Topdown "thought island" chat-output style (skill + per-turn nudge hook) |

## Repository structure

```
duperpowers/
├── features/
│   ├── _lib/feature-hooks.sh        # hook dispatcher (shared infra)
│   ├── session-state/               # INSTALL.md + scripts/
│   ├── prompt-engineering-rules/    # INSTALL.md + skills/
│   ├── mit-writer/                  # INSTALL.md + skills/
│   └── output-format/               # INSTALL.md + skills/ + hooks/
├── templates/claude-md-snippet.md   # optional personal-preferences append (not a feature)
├── INSTALL.md                       # the single install entry (agent-facing)
├── CLAUDE.md
└── README.md
```

## Personal preferences (optional)

[`templates/claude-md-snippet.md`](templates/claude-md-snippet.md) is the author's optional CLAUDE.md
snippet (commit conventions, validation rules, output format). Copy or adapt the relevant sections
into your own `~/.claude/CLAUDE.md` manually. It is not a feature and is not installed by `INSTALL.md`.

## Contributing a feature

See [`INSTALL.md`](INSTALL.md) and the "Adding a Feature" section of [`CLAUDE.md`](CLAUDE.md). In short:

1. Create `features/<name>/INSTALL.md` with frontmatter (`name` / `description` / `dependencies` /
   `platform` / `provides`).
2. Put leaf items under `features/<name>/{skills,agents,scripts,hooks}/`.
3. Add a row to the feature index in `INSTALL.md` and to the Features table above.

## License

MIT
