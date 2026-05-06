# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Duperpowers-go — Claude Code / Cursor plugin extending [superpowers](https://github.com/obra/superpowers) with standalone Go skills (writing, testing, review, verification) and targeted overrides for superpowers defaults that conflict with this user's Go workflow. Pure markdown/bash/JSON.

**No pipeline.** v0.0.x carried a pseudocode-pipeline (L0/L1/L1.5/L2) with sonnet fan-out via `dispatch`. Removed in `0.1.0` after the spine-rule realization (2026-04-28): user writes code, Claude expands user-placed TODOs, reviews, advises. Pipeline orchestration was the inverse — Claude implementing, user reviewing — and produced the "70% problem". Pre-cut state preserved at git tag `pipeline-era`.

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

1. **session-start** (SessionStart) — reads `using-duperpowers/SKILL.md`, wraps in `<IMPORTANT>` with Go skill pairings, outputs platform-specific JSON. Fires on startup/clear/compact.
2. **skill-override** (PreToolUse:Skill) — if invoked skill is `superpowers:*`, injects reminder to also invoke `superpowers-overrides`. Claude Code only (Cursor lacks PreToolUse).

### User Preferences Propagation

`templates/claude-md-snippet.md` is the source of truth for personal preferences. INSTALL.md step 4 fetches it from GitHub and appends to `~/.claude/CLAUDE.md`. On new device: run INSTALL.md again — plugin + standalone skills restore automatically, preferences restore from template (~80%), custom additions (like `@RTK.md`) are manual.

### Skills (7 + 1 subagent)

Under `plugins/duperpowers-go/skills/`:

| Skill | Purpose |
|-------|---------|
| `using-duperpowers` | Session preamble — priority stack, override trigger, skill index |
| `superpowers-overrides` | Targeted overrides for superpowers defaults; loaded on any superpowers skill |
| `go-writer` | Project Go conventions for `*.go` |
| `go-writer-test` | Project Go test conventions for `*_test.go` |
| `go-reviewer` | Spec + quality review modes; PASS/FAIL with file:line evidence |
| `verify` | gocheck + dpcheck (pure check, no mutation); routes superpowers verification on Go code |
| `research` | Codebase exploration, topic files + INDEX.md (claude-as-copilot pattern) |
| `mit-writer` | MIT-outline notes (user-facing) |

Plus `gocheck` sonnet subagent — Go build/vet/test-compile verification, invoked by `verify`.

### Historical Files

- `plans/research.md` — MIT-format research notes from before building duperpowers. Analyzed superpowers patterns, led to early architecture. NOT a current spec.
- Git tag `pipeline-era` (commit `cec1706`, v0.0.25) — snapshot of the pseudocode-pipeline era before its removal in `0.1.0`. Reference for what was tried, what worked, and why it was cut. See git log around `0.1.0` for the rationale.

## Conventions

### Adding a Skill

1. Create `plugins/duperpowers-go/skills/<skill-name>/SKILL.md`
2. Add to skill index in `using-duperpowers/SKILL.md`
3. Update README.md skills table
4. If skill needs hook integration, update `hooks/hooks.json`

### Skill Files

- Frontmatter: `name` (hyphens only) + `description` starting with a trigger phrase ("Use when...", "Use at...", "MUST invoke when...", or a terse project-noun phrase for reference skills such as `go-writer`)
- Rule IDs are append-only (prefix per skill — see each skill's golden rules section). IDs only — rule **content** may be reframed in place; mention substantive reframes in the commit message so `git log` surfaces the pivot.
- `<IMPORTANT>` top + anchor bottom for golden rules
    - Short skills (~50 lines or less) that are entirely an `<IMPORTANT>` block may omit the bottom anchor — the whole skill IS the anchor. Reference-style skills without rule lists (e.g., `mit-writer`) may omit `<IMPORTANT>` entirely.
- Cross-skill references by `duperpowers-go:skill-name`, never file paths

### Commits

- Never add `Co-Authored-By: Claude*` or AI attribution
- ALWAYS bump version in both `plugin.json` files with every commit that changes plugin content (skills, templates, hooks, README)
- Version in both `plugin.json` files must stay in sync
- Never stage: `.claude/*`, `task*.md`, `plans/*`, `docs/plans/*`, `docs/specs/*`. The user's home `~/.claude/CLAUDE.md` is off-limits too — the project `CLAUDE.md` at the repo root is tracked and edited normally.
