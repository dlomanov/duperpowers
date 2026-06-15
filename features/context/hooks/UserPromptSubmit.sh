#!/usr/bin/env bash
# UserPromptSubmit hook: every N turns of work, nudge to append accumulated context
# to the WAL. The model reads the nudge and decides whether anything is worth writing
# (a shell script can't judge importance). The append itself is inline (logwriter append),
# not a command. When the WAL is oversize the nudge also tells the model to suggest /precompact.
set -uo pipefail

# No jq (e.g. another laptop) → degrade to a silent no-op, never break the session
command -v jq >/dev/null 2>&1 || exit 0

N=4   # turns between nudges; tune here

# Hooks are reached via a symlink in hooks/<Event>.d/, so resolve siblings from the
# config dir (where scripts/ always lives), NOT from BASH_SOURCE (that points at .d/).
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
DIR="$CFG/session_state"
KV="$CFG/scripts/kv.sh"
LW="$CFG/scripts/logwriter.sh"

input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[[ -z "$sid" ]] && exit 0

STATE="$DIR/$sid.state"
n=$("$KV" --file "$STATE" incr context.turns_since_flush 2>/dev/null) || exit 0

if (( n >= N )); then
    "$KV" --file "$STATE" set context.turns_since_flush 0 2>/dev/null || true
    WAL="${DIR}/${sid}.wal"
    ctx="session-context: ${n} turns since the WAL was last appended to. If meaningful decisions, dead ends, constraints, or a shifted next-step have accumulated since then, append that delta inline now via ~/.claude/scripts/logwriter.sh --wal ${WAL} append \"<delta>\" (write only the NEW non-reconstructable facts from your live context - do NOT read the WAL first). If nothing worth persisting, ignore this."
    # Guard: oversize is advisory; a non-zero/erroring logwriter must never abort the hook.
    if "$LW" --wal "$WAL" oversize 2>/dev/null; then
        ctx="${ctx} The WAL is over its size threshold - tell the user it is oversize and suggest they run /precompact (precompact is user-only; do not run it yourself)."
    fi
    printf '%s\n' "$ctx"   # plain text; the feature-hooks dispatcher wraps it in JSON
fi
exit 0
