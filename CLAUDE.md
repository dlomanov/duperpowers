# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Duperpowers-go — Claude Code / Cursor plugin extending [superpowers](https://github.com/obra/superpowers) with a Go development pipeline. Originally planned as two plugins (core + Go), merged into one. Pure markdown/bash/JSON, version 0.0.1.

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

### Historical Files

`proposal.md` — execution report from a real production task (ACQ-19510), not a current spec. Documents issues and prompt fixes.

`plans/research.md` — MIT-format research notes from before building duperpowers. Analyzed superpowers patterns, led to current architecture. NOT a current spec — the two-plugin structure described there was later merged into one.

## Conventions

### Adding a Skill

1. Create `plugins/duperpowers-go/skills/<skill-name>/SKILL.md`
2. Add to skill index in `using-duperpowers/SKILL.md`
3. Update README.md skills table
4. If skill needs hook integration, update `hooks/hooks.json`

### Skill Files

- Frontmatter: `name` (hyphens only) + `description` (start with "Use when...")
- Rule IDs are append-only (GP-1, TG-3, RR-1, PR-11, etc.)
- `<IMPORTANT>` top + anchor bottom for golden rules
- Cross-skill references by `duperpowers-go:skill-name`, never file paths

### Commits

- Never add `Co-Authored-By: Claude*` or AI attribution
- Version in both `plugin.json` files must stay in sync
- Never commit: CLAUDE.md, .claude/*, task*.md, plans/*
