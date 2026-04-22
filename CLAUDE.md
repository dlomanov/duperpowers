# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Duperpowers-go — Claude Code / Cursor plugin extending [superpowers](https://github.com/obra/superpowers) with a Go development pipeline organized around pseudocode-in-code and verifiable level guarantees. Pure markdown/bash/JSON.

## Testing Changes

```bash
claude plugin install duperpowers-go   # install from local checkout
# start new session, then:
> Tell me about your duperpowers
```

No automated tests. Verification: install, start session, confirm hooks fire and skills load.

## Architecture

### Hook Chain (per session)

Two hooks in `plugins/duperpowers-go/hooks/`:

1. **session-start** (SessionStart) — reads `using-duperpowers/SKILL.md`, wraps in `<IMPORTANT>` with Go skill pairings, outputs platform-specific JSON. Also probes CWD for `TODO:` markers in `*.go`; if found, appends a one-line BRANCH STATE hint steering to `duperpowers-go:verify`. Fires on startup/clear/compact.
2. **skill-override** (PreToolUse:Skill) — if invoked skill is `superpowers:*`, injects reminder to also invoke `superpowers-overrides`. Claude Code only (Cursor lacks PreToolUse).

### User Preferences Propagation

`templates/claude-md-snippet.md` is the source of truth for personal preferences. INSTALL.md step 4 fetches it from GitHub and appends to `~/.claude/CLAUDE.md`. On new device: run INSTALL.md again — plugin + standalone skills restore automatically, preferences restore from template (~80%), custom additions (like `@RTK.md`) are manual.

### Pseudocode Pipeline (levels as guarantees)

Implementation is organized around **levels (L0/L1/L1.5/L2)** = monotonically growing lists of verifiable branch-state guarantees. Levels are changed by **transition** skills; **modifier** skills check guarantees without mutating state. Plan lives in code (pseudocode + `TODO:` markers at exact locations), not in prose.

Levels:

| L | State | Guarantees |
|---|-------|-----------|
| L0 | Raw spec / natural-language intent | None beyond the spec itself |
| L1 | Production pseudocode at exact code locations | Go compiles; contracts real; `TODO:` markers resolvable |
| L1.5 | Test pseudocode + populated case tables | L1 + tests build; case rows complete; no panicking stubs |
| L2 | Sonnet resolved every `TODO:` | L1.5 + gocheck + dpcheck + verify PASS + review PASS + plan.md committed |

Transitions:

| From → To | Skill | Model |
|-----------|-------|-------|
| L0 → L1 | `duperpowers-go:pseudocode-writer` | opus |
| L1 → L1.5 | `duperpowers-go:pseudocode-writer-test` | opus |
| L1.5 → L2 | `duperpowers-go:dispatch` (plan.md + sonnet fan-out + verify + review + fix-loop) | opus + sonnet fan-out |

Modifiers (pure, no mutation):

| Skill | Purpose | Model |
|-------|---------|-------|
| `duperpowers-go:verify` | gocheck + dpcheck + level-specific guarantee checks | sonnet |
| `duperpowers-go:review` | level-aware semantic review; L2 = 2 reviewer opuses + 1 consolidator | opus |

Enforcement runs in 4 layers: mechanical (verify + gocheck + dpcheck) → procedural (writer skills) → semantic (review) → user. Fix-loop budget ≤ 2 iter, then escalate to user (BLOCKED).

`plan.md` is a **dispatch artifact** (summary + pointer map + DAG + agent table + DoD checklist) — logic is not duplicated there; logic lives in code.

### Skill Index (12 skills + 1 subagent)

Under `plugins/duperpowers-go/skills/`:

| Skill | Purpose |
|-------|---------|
| `using-duperpowers` | Session preamble, priority stack, skill index |
| `research` | Pre-planning codebase exploration, topic files + INDEX.md |
| `superpowers-overrides` | Overrides superpowers defaults, loaded on any superpowers skill |
| `pseudocode-writer` | L0 → L1 transition — production pseudocode + `TODO:` markers |
| `pseudocode-writer-test` | L1 → L1.5 transition — test pseudocode + populated cases tables |
| `dispatch` | L1.5 → L2 composite — plan.md + sonnet fan-out + verify + review + fix-loop |
| `verify` | gocheck + dpcheck + level-specific guarantee checks (pure modifier) |
| `review` | Level-aware semantic review (L0/L1/L1.5/L2); mandatory at L2 |
| `go-writer` | Project Go conventions for `*.go` |
| `go-writer-test` | Project Go test conventions for `*_test.go` |
| `go-reviewer` | Spec + quality review modes, PASS/FAIL with file:line |
| `mit-writer` | MIT-outline notes (user-facing, no pipeline role) |

Plus `gocheck` sonnet subagent — Go build/test/lint verification invoked by `verify`.

### Historical Files

`plans/research.md` — MIT-format research notes from before building duperpowers. Analyzed superpowers patterns, led to current architecture. NOT a current spec — the two-plugin structure described there was later merged into one.

## Conventions

### Adding a Skill

1. Create `plugins/duperpowers-go/skills/<skill-name>/SKILL.md`
2. Add to skill index in `using-duperpowers/SKILL.md`
3. Update README.md skills table
4. If skill needs hook integration, update `hooks/hooks.json`

### Skill Files

- Frontmatter: `name` (hyphens only) + `description` starting with a trigger phrase ("Use when...", "Use at...", "MUST invoke when...", or a terse project-noun phrase for reference skills such as `go-writer`)
- Rule IDs are append-only (PW-*, PWT-*, VF-*, REV-*, DSP-*, GP-*, TG-*, RR-*, etc.)
- `<IMPORTANT>` top + anchor bottom for golden rules
- Cross-skill references by `duperpowers-go:skill-name`, never file paths

### Commits

- Never add `Co-Authored-By: Claude*` or AI attribution
- ALWAYS bump version in both `plugin.json` files with every commit that changes plugin content (skills, templates, hooks, README)
- Version in both `plugin.json` files must stay in sync
- Never stage: `.claude/*`, `task*.md`, `plans/*`, `docs/plans/*`, `docs/specs/*`. The user's home `~/.claude/CLAUDE.md` is off-limits too — the project `CLAUDE.md` at the repo root is tracked and edited normally.
