# Duperpowers

Superpowers companion — universal planning, orchestration, and Go conventions for Claude Code and Cursor.

Two plugins, one marketplace:
- **duperpowers** — universal planning, orchestration, and superpowers overrides
- **duperpowers-go** — Go conventions, testing, and code review (optional)

## Prerequisites

- [superpowers](https://github.com/obra/superpowers) plugin (required)
- [RTK](https://github.com/anthropics/rtk) (optional): `brew install rtk && rtk init -g`

## Quick Install

Tell Claude:

```
Fetch and follow instructions from https://raw.githubusercontent.com/dlomanov/duperpowers/main/SETUP.md
```

## Manual Install

### Claude Code

```bash
# Add marketplace
claude plugin marketplace add dlomanov/duperpowers

# Install core (required)
claude plugin install duperpowers

# Install Go skills (optional)
claude plugin install duperpowers-go

# Full install (one line)
claude plugin install duperpowers && claude plugin install duperpowers-go
```

Install order: superpowers first, then duperpowers, then duperpowers-go.

### Cursor

```
/add-plugin duperpowers
/add-plugin duperpowers-go
```

## CLAUDE.md Customization

The plugins work without touching your CLAUDE.md. For personal preferences (commit conventions, progress visibility, validation rules), see [`templates/claude-md-snippet.md`](templates/claude-md-snippet.md) and append the relevant sections to your `~/.claude/CLAUDE.md`.

## Repository Structure

```
duperpowers/
├── .claude-plugin/
│   └── marketplace.json                   # lists both plugins
├── plugins/
│   ├── duperpowers/                       # core plugin
│   │   ├── .claude-plugin/plugin.json
│   │   ├── .cursor-plugin/plugin.json
│   │   ├── hooks/                         # session-start + PreToolUse hooks
│   │   └── skills/                        # 10 universal skills
│   └── duperpowers-go/                    # Go plugin (optional)
│       ├── .claude-plugin/plugin.json
│       ├── .cursor-plugin/plugin.json
│       ├── hooks/                         # Go-specific context injection
│       ├── agents/gocheck.md              # Go verification agent
│       └── skills/                        # 4 Go skills
├── standalone/
│   └── project-commands/              # standalone skill (manual install)
│       ├── SKILL.md                   # template — adapt to your project
│       └── INSTALL.md                 # fetch-and-follow installer
├── templates/
│   └── claude-md-snippet.md               # personal preferences template
├── SETUP.md                               # fetch-and-follow installer
└── README.md
```

## Skills Reference

### Core (duperpowers)

| Skill | Purpose |
|-------|---------|
| `using-duperpowers` | Session bootstrap — override triggers, anchor rules, protocols |
| `plan-orchestrator` | Full workflow: brainstorm → plan → assign → review → execute |
| `plan-reviewer` | Validates plan structure, PASS/FAIL verdicts |
| `agent-assignment` | Dependency graph + agent table after writing plans |
| `want-planning` | Transition to plan writing, re-reads context |
| `gatekeeper` | Last checkpoint before coding, GO/NO-GO |
| `superpowers-overrides` | Universal overrides for superpowers defaults |
| `verify` | Build + minimal sufficient tests after changes |
| `diminishing-returns` | Tracks plan revision quality, suggests proceed |
| `mit-writer` | Hierarchical outline notes |

### Go (duperpowers-go)

| Skill | Purpose |
|-------|---------|
| `go-writer` | Go conventions, 5 golden rules, modern Go 1.22+ |
| `go-writer-test` | Go test conventions, AAA, table-driven, mocks |
| `go-reviewer` | Two modes: spec + quality, PASS/FAIL verdicts |
| `make-go-review` | Quick review wrapper for branch diff |
| `gocheck` (agent) | Go build/test/lint verification |

### Standalone

| Skill | Purpose | Install |
|-------|---------|---------|
| `project-commands` | Make targets, test commands, go doc protocol | [INSTALL.md](standalone/project-commands/INSTALL.md) |

Not part of plugins — install manually per project or globally. The SKILL.md is a template to adapt.

```
Fetch and follow instructions from https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/project-commands/INSTALL.md
```

## How Overrides Work

Both plugins inject context via session-start hooks. The injections are **additive** — Claude sees both:

1. **Core hook** injects full `using-duperpowers` skill at session start (override triggers, anchor rules, subagent injection, error escalation). Additionally, a PreToolUse hook fires on every Skill invocation — when a superpowers skill loads, it injects a reminder to also invoke superpowers-overrides
2. **Go hook** injects: Go anchor rules, Go skill pairings with superpowers (TDD → go-writer-test, review → go-reviewer)

Superpowers' own priority hierarchy ensures this works:
1. User instructions (CLAUDE.md) — highest priority
2. Plugin skills (superpowers + duperpowers) — override defaults
3. Default system prompt — lowest priority

## For Contributors

### Adding a skill

1. Create `plugins/<plugin>/skills/<skill-name>/SKILL.md`
2. Add YAML frontmatter with `name`, `description`
3. Use trigger patterns in description: `"Use when [condition] — [what it does]"`
4. Update this README

### Testing locally

```bash
# Install from local repo
cd duperpowers
claude plugin install duperpowers
claude plugin install duperpowers-go

# Start new session and verify
claude
> Tell me about your duperpowers
```

## License

MIT
