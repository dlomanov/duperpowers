#!/usr/bin/env bash
# SessionStart hook: restores prior session context by injecting it via additionalContext.
# - compact/resume: restore this session's own WAL (it carries the pre-compact records)
# - startup:        restore the most recent prior WAL
# - clear:          no restore (user wiped context on purpose)
# On a stale summary it instructs the main thread to spawn context-reader
# (a hook cannot spawn agents itself) instead of injecting stale text.
set -uo pipefail

# No jq (e.g. another laptop) → degrade to a silent no-op, never break the session
command -v jq >/dev/null 2>&1 || exit 0

# Hooks are reached via a symlink in hooks/<Event>.d/, so resolve siblings from the
# config dir (where scripts/ always lives), NOT from BASH_SOURCE (that points at .d/).
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
DIR="$CFG/session_state"
LW="$CFG/scripts/logwriter.sh"

input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
src=$(printf '%s' "$input" | jq -r '.source // empty')

[[ -z "$sid" ]] && exit 0   # nothing addressable without a session id

CUR="$DIR/$sid.wal"

emit() {  # $1 = additionalContext text (plain; the feature-hooks dispatcher wraps it in JSON)
    printf '%s\n' "$1"
}

if [[ "$src" == "clear" ]]; then
    emit "session-context: context cleared. This session's WAL=$CUR (append notes inline via ~/.claude/scripts/logwriter.sh --wal $CUR append \"<note>\")."
    exit 0
fi

# Restore source: this session's WAL if it has content, else the most recent prior WAL.
if [[ -s "$CUR" ]]; then
    RWAL="$CUR"
else
    RWAL=$(ls -t "$DIR"/*.wal 2>/dev/null | head -n1 || true)
fi

if [[ -z "${RWAL:-}" || ! -s "$RWAL" ]]; then
    emit "session-context: no prior WAL found. This session's WAL=$CUR (append notes inline via ~/.claude/scripts/logwriter.sh --wal $CUR append \"<note>\")."
    exit 0
fi

SUM="$RWAL.sum"
if "$LW" --wal "$RWAL" stale; then   # exit 0 = STALE
    emit "session-context: a prior WAL exists at $RWAL but its summary is STALE. To restore it, run the session-context skill (spawn the context-reader agent with WAL=$RWAL, then read the .sum it returns). Append this session's notes inline to WAL=$CUR via ~/.claude/scripts/logwriter.sh --wal $CUR append \"<note>\"."
else                                  # exit 1 = FRESH
    body=$(cat "$SUM")
    emit "session-context restored from $RWAL:

$body

---
This session's WAL=$CUR. Append new notes inline via ~/.claude/scripts/logwriter.sh --wal $CUR append \"<note>\"."
fi
exit 0
