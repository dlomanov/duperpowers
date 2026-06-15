---
name: recall-context
description: Search prior sessions' WAL summaries for a topic. Use when the user asks to recall / remember / "вспомни про X" / "что мы решали про X" across past sessions. Two-tier search - match topics headers first, read only matching summary bodies - so token cost stays low.
---

# Recall Across Sessions

## 1. Derive search keys
From the user's ask, derive 2-4 lowercase English keywords (topics lines hold concrete nouns: feature / file / module / subsystem / decision names). Include likely synonyms - e.g. "вспомни про логи" (recall about logs) -> keys: `wal, logwriter, logging`.

## 2. Refresh coverage
Summaries are the search index; a missing or stale `.sum` is invisible to the search.
First check there is anything to search: `ls ~/.claude/session_state/*.wal 2>/dev/null` - if empty, tell the user no prior sessions exist and stop.

For each `.wal`:

    ~/.claude/scripts/logwriter.sh --wal "<wal-path>" stale

- exit 1 = FRESH -> skip
- exit 0 = STALE / no `.sum` -> spawn `context-reader`, prompt is just the assignment line: `WAL=/absolute/path/to/<sid>.wal`

Foreign-WAL size is not a gate - always summarize via `context-reader` regardless of size (the reader decodes to a sidecar and paginates, so a big WAL is fine). When `~/.claude/scripts/logwriter.sh --wal "<wal-path>" oversize` exits 0, just emit one passive line to the user - `note: <sid>.wal is NKB; run /precompact in that session to shrink it` - then summarize normally. Do not block, do not ask, do not compact a foreign WAL yourself.

Spawn all needed readers in ONE message (they run in parallel). A reader returning `EMPTY: ...` means that WAL has no records - exclude it.

## 3. Cheap match - headers only

    grep -i -l -E "^topics:.*(wal|logwriter)" ~/.claude/session_state/*.wal.sum

(`wal|logwriter` shown as an example - substitute your keys from step 1.)

## 4. Read matches only
Read the body of each matching `.sum`. Synthesize the answer from those bodies; cite which session file each fact came from.

## 5. Fallbacks, in order
1. No topics match -> search whole `.sum` bodies with the same keys, read hits:

       grep -i -l -E "(wal|logwriter)" ~/.claude/session_state/*.wal.sum

2. Still nothing -> tell the user nothing matched and list available topics:

       grep -h "^topics:" ~/.claude/session_state/*.wal.sum

   Offer to search raw WALs as a last resort - expensive, only on explicit yes:

       ~/.claude/scripts/logwriter.sh --wal "<wal-path>" read --full

## Self-improvement
If a step here contradicts observed behavior (command fails, wrong path, wrong exit code, missing branch), diagnose the mismatch and propose an edit to this SKILL.md. Apply it ONLY after the user approves. Never rewrite silently.
