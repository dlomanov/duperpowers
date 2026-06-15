---
name: precompact
description: Use when the user runs /precompact to losslessly compact the current session WAL. Flushes the live delta, then dedups the wal into a verified checkpoint and swaps it in.
disable-model-invocation: true
---

# /precompact

User-only. Losslessly compacts THIS session's own wal so it never grows unbounded. Single
sequential writer (the hook only bumps a counter; context-reader writes only `<wal>.sum`), so
no lock, no snapshot, no tail-merge. Run each step in order. `$WAL` is this session's wal
(absolute path, ends `.wal`). All `kv.sh` calls pass `--file "${WAL%.wal}.state"`.

LW=~/.claude/scripts/logwriter.sh
KV=~/.claude/scripts/kv.sh

## 0. PREFLIGHT - self-heal crash litter
A crash mid-swap can leave `${WAL}.old` and a stale `${WAL}.ckpt`. Resolve, then sweep. Three
cases:
- `$WAL` present AND `${WAL}.old` present -> crashed AFTER the new wal landed. The new wal is
  good: `rm -f "${WAL}.old" "${WAL}.ckpt"`. Continue.
- `$WAL` MISSING AND `${WAL}.old` present -> crashed BEFORE the new wal landed. Restore:
  `mv "${WAL}.old" "$WAL"`. Then sweep.
- else -> sweep.

Sweep by EXPLICIT names only - NEVER a glob, which would also delete `${WAL}.txt` (the live
context-reader sidecar):

    rm -f "${WAL}.ckpt" "${WAL}.compact.txt" "${WAL}.verify.txt" "${WAL}.old"

## 1. FLUSH - append the session DELTA from LIVE context
Synthesize the delta NOW from your live context - do NOT read the wal. Append ONLY what a
future session cannot reconstruct from code, git, or CLAUDE.md, AND only what is new or changed
since the last flush this session:
- current task/goal, where it stands, the next concrete step
- decisions with WHY and the rejected alternatives
- dead ends and why they failed
- discovered constraints and hard-won mechanics
- open questions
- pointers to files/symbols

Free text, ONE append. If nothing is new, SKIP the append entirely.

GOOD: `chose sqlite over pg - no network dep; pg failed on auth; next: wire migrations in db/init.go`
BAD:  `edited several files and fixed the bug`  (derivable from the diff)

If there IS a new delta:

    printf '%s' "$DELTA" | "$LW" --wal "$WAL" append
    "$KV" --file "${WAL%.wal}.state" set context.turns_since_flush 0

## 2. GATE - need >= 2 records to be worth compacting
`append` always ends with a trailing newline and is the sole writer, so physical lines ==
records:

    N=$(wc -l < "$WAL")

If `N <= 1` the wal is already canonical. Report DONE - nothing to compact. STOP.

## 3. COMPACT
Spawn the `wal-compactor` agent with `WAL=$WAL`. It returns `${WAL}.ckpt`.

## 4. DECIDE + VERIFY
4a. Skip the verifier when compaction barely shrank the wal - verification guards lossy
deletion, negligible when little was removed. SHRINK_MIN is 90%:

    OLD_B=$(wc -c < "$WAL")
    CKPT_B=$(wc -c < "${WAL}.ckpt")

If `CKPT_B * 100 >= OLD_B * 90`, then `rm -f "${WAL}.ckpt"`, report "near-canonical, nothing
to compact", DONE. STOP.

4b. Else spawn the `wal-verifier` agent with `OLD=$WAL CKPT=${WAL}.ckpt`.
- PASS -> record the checkpoint hash NOW for the SWAP re-check, then go to 5:

      CKPT_HASH=$("$LW" --wal "${WAL}.ckpt" hash)

- FAIL -> ONE repair attempt: continue the SAME `wal-compactor` via SendMessage with the
  verifier loss list. Then re-verify by continuing the SAME `wal-verifier` via SendMessage.
  - re-verify PASS -> record `CKPT_HASH` as above, go to 5.
  - re-verify FAIL again -> `rm -f "${WAL}.ckpt"`, report BLOCKED with the loss list. The old
    wal is untouched. STOP.

## 5. SWAP
Validate cheaply - the verifier already proved decode and faithful facts, so do NOT decode
again. Require the checkpoint to be non-empty AND its hash to equal the one recorded at PASS:

    [[ -s "${WAL}.ckpt" ]] && [[ "$("$LW" --wal "${WAL}.ckpt" hash)" == "$CKPT_HASH" ]]

If either fails -> `rm -f "${WAL}.ckpt"`, report BLOCKED, old wal untouched. STOP.

Otherwise swap (same dir = same fs = atomic rename), keeping the old copy aside until the new
wal is in place so a crash mid-swap is recoverable by PREFLIGHT:

    mv "$WAL" "${WAL}.old"
    mv "${WAL}.ckpt" "$WAL"
    rm -f "${WAL}.old"

Do NOT rebuild `.sum` - its `hash:` no longer matches, so `stale` flags it and it rebuilds
lazily. Report bytes before (`OLD_B`) and after (`CKPT_B`). DONE.
