# Duperpowers Go

Superpowers companion — Go development pipeline: planning, orchestration, TDD, conventions, testing, code review.

One plugin: **duperpowers-go** — everything in one package.

## Prerequisites

- [superpowers](https://github.com/obra/superpowers) plugin (required)
- [RTK](https://github.com/anthropics/rtk) (optional): `brew install rtk && rtk init -g`

## Quick Install

Works in both Claude Code and Cursor. Tell your AI:

```
Fetch and follow instructions from https://raw.githubusercontent.com/dlomanov/duperpowers/main/INSTALL.md
```

This will detect your platform, install superpowers (if missing), duperpowers-go, and offer to configure anchor rules, personal preferences, and standalone skills. The installer is idempotent.

## Manual Install

### Claude Code

```bash
# Add marketplace
claude plugin marketplace add dlomanov/duperpowers

# Install
claude plugin install duperpowers-go
```

If old `duperpowers` (without -go) is installed: `claude plugin uninstall duperpowers`

### Cursor

```
/add-plugin superpowers
/add-plugin duperpowers-go
```

## CLAUDE.md Customization

The plugin works without touching your CLAUDE.md. For personal preferences (commit conventions, progress visibility, validation rules), see [`templates/claude-md-snippet.md`](templates/claude-md-snippet.md) and append the relevant sections to your `~/.claude/CLAUDE.md`.

## Repository Structure

```
duperpowers/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   └── duperpowers-go/
│       ├── .claude-plugin/plugin.json
│       ├── .cursor-plugin/plugin.json
│       ├── hooks/                         # session-start + PreToolUse hooks
│       ├── agents/gocheck.md              # Go verification agent
│       └── skills/                        # 13 skills
├── standalone/
│   ├── project-commands/
│   │   ├── SKILL.md
│   │   └── INSTALL.md
│   └── prompt-engineering-rules/
│       ├── SKILL.md
│       └── INSTALL.md
├── templates/
│   └── claude-md-snippet.md
├── INSTALL.md
└── README.md
```

## Skills Reference

| Skill | Purpose |
|-------|---------|
| `using-duperpowers` | Session bootstrap — override triggers, skill index |
| `plan-orchestrator` | Workflow: brainstorm → research → plan → assign → execute |
| `research` | Explore codebase topics before planning (research files + INDEX) |
| `agent-assignment` | Dependency graph, contract extraction, agent table, validation |
| `tdd-design` | Test design during planning (case table with hints) |
| `superpowers-overrides` | Overrides for superpowers defaults |
| `go-writer` | Go conventions, golden rules, modern Go 1.22+ |
| `go-writer-test` | Go test conventions, AAA, table-driven, mocks |
| `go-reviewer` | Two modes: spec + quality, PASS/FAIL verdicts |
| `make-go-review` | Deep review wrapper for branch diff |
| `mit-writer` | Hierarchical outline notes |
| `want-planning` | Focus recovery before planning (`/want-planning`) |
| `want-executing` | Focus recovery before execution (`/want-executing`) |
| `gocheck` (agent) | Go build/test/lint verification |

### Standalone

| Skill | Purpose | Install |
|-------|---------|---------|
| `project-commands` | Make targets, test commands, go doc protocol | [INSTALL.md](standalone/project-commands/INSTALL.md) |
| `prompt-engineering-rules` | Reference for writing CLAUDE.md, SKILL.md, AI instruction files | [INSTALL.md](standalone/prompt-engineering-rules/INSTALL.md) |
| `english-practice` | Passive English practice — responds in English, corrects grammar | [INSTALL.md](standalone/english-practice/INSTALL.md) |

Not part of the plugin — install manually per project or globally.

```
Fetch and follow instructions from https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/project-commands/INSTALL.md
Fetch and follow instructions from https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/prompt-engineering-rules/INSTALL.md
Fetch and follow instructions from https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/english-practice/INSTALL.md
```

## How Overrides Work

The plugin injects context via session-start hook: full `using-duperpowers` skill + Go skill pairings. A PreToolUse hook fires on every Skill invocation — when a superpowers skill loads, it reminds to also invoke superpowers-overrides.

Priority hierarchy:
1. User instructions (CLAUDE.md) — highest
2. Plugin skills (superpowers + duperpowers-go)
3. Default system prompt — lowest

## For Contributors

### Adding a skill

1. Create `plugins/duperpowers-go/skills/<skill-name>/SKILL.md`
2. Add YAML frontmatter with `name`, `description`
3. Use trigger patterns in description: `"Use when [condition]"`
4. Update this README

### Testing locally

```bash
cd duperpowers
claude plugin install duperpowers-go

# Start new session and verify
claude
> Tell me about your duperpowers
```

## License

MIT
