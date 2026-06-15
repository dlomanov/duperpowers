---
name: session-context
description: Restore prior session context, or read/write the session WAL log. Use when resuming work, when the user asks to recover/restore/recall context, or when deciding to record a session note. Checks the summary-cache freshness first so the reader agent is spawned only when actually needed.
---

# Session Context

## Pieces
- `~/.claude/scripts/logwriter.sh` - the WAL. `append <text>` | `read --full` | `hash` | `stale [sum-path]` | `oversize`
- `context-reader` agent (opus) - summarizes a WAL into `<wal>.sum` (header `hash:` / `topics:` + body), returns the path only

## Restore prior context
ALWAYS run `stale` yourself first. Spawn `context-reader` ONLY on exit 0.

WAL path: it lives at `~/.claude/session_state/<sid>.wal`. Use the `WAL=<path>` the SessionStart hook injected into context. Otherwise glob `~/.claude/session_state/*.wal`; if several match, pick the most recent (`ls -t`) or ask which session.

    ~/.claude/scripts/logwriter.sh --wal "$WAL" stale

Exit codes are inverted from the Unix default - read carefully:
- **exit 1 = FRESH** → `<WAL>.sum` is current. Read it and use its contents as the restored context.
- **exit 0 = STALE / no `.sum`** → spawn `context-reader` with `WAL=<path>` regardless of WAL size (the reader decodes to a sidecar and paginates - big WALs are fine). It rewrites `<WAL>.sum` and returns the path. Read that file and use it as context. If `~/.claude/scripts/logwriter.sh --wal "$WAL" oversize` exits 0, also emit one passive line to the user - `note: <sid>.wal is NKB; run /precompact in that session to shrink it` - then proceed normally. Do not block, do not ask, do not compact.
- **reader returns `EMPTY: ...`** → no prior context exists. Tell the user, proceed without it.

## Write a session note (during work)
    ~/.claude/scripts/logwriter.sh --wal "$WAL" append "<note>"

Record only what a future session cannot reconstruct from code, git, or CLAUDE.md:
decisions + why + rejected alternatives, dead ends + why, discovered constraints,
open questions, current task + next step, file pointers. Free text, no tags.

    GOOD: "chose sqlite over pg - no network dep; tried pg first, failed on auth setup"
    BAD:  "updated the database module"   (derivable from the diff - noise)

## Recall across sessions
Use the `recall-context` skill - two-tier search (grep `topics:` first, read only matches).

## Self-improvement
If a step here contradicts observed behavior (command fails, wrong path, wrong exit code, missing branch), diagnose the mismatch and propose an edit to this SKILL.md. Apply it ONLY after the user approves. Never rewrite silently.
