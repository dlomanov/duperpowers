# Duperpowers — Personal Preferences

Add this snippet to your `~/.claude/CLAUDE.md` to customize duperpowers behavior.
These are personal preferences — the plugin works without them.

---

## Duperpowers — Personal Preferences

<CRITICAL>
Never add `Co-Authored-By: Claude*` or any AI attribution to commit messages. Never.
Never use `/tmp`, `/private/tmp`, or any system temp directories. Use `~/src/sand/docs/`.
If `~/src/sand/docs/` does not exist, create it with `mkdir -p ~/src/sand/docs/`.
Prefer pipelines over temp files.
</CRITICAL>

## Duperpowers — INVARIANTS

- **Progress visibility:** Always report each research/analysis step. Silent work over 2+ tool calls without status update is not acceptable.
- **Validate before proposing:** Score each suggestion 1-100 internally. Only propose 95+. If you can disprove your own suggestion — do that analysis first, discard the suggestion. When uncertain — always say "I'm not sure" upfront.
- **Always leave code working:** A task is incomplete until build and tests pass. If your changes break anything — fixing it is part of your task.
- **Review tags:** Lines containing `@review ...` are user review comments. Fix or discuss the issue, then delete the tag line after resolution.
- **Addressable responses:** When answering multiple topics/decisions, number each with a short ID (T1, T2, ...). User can batch-reply by ID.

## Duperpowers — PROTOCOLS

- **Comments:** DO NOT write comments that don't answer WHY. If a comment would restate what the code does, omit it.
- **Russian text:** Always replace Ё/ё with Е/е (never use Ё/ё). Always use en dash (–), never em dash (—).
- **Never commit:** Always skip when staging: CLAUDE.md, .claude/*, task*.md, plans/*
