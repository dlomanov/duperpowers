#!/usr/bin/env bash
# Hook dispatcher for the features mechanism.
#
# settings.json wires ONE entry per event: `feature-hooks.sh <Event>`. This runs every
# script in $CFG/hooks/<Event>.d/ and merges their plain-text stdout into a single
# additionalContext JSON envelope.
#
# Child contract: each <Event>.d/* script reads the hook payload on stdin and prints
# ONLY its additionalContext text (plain, may be empty/multiline) — NOT a JSON envelope.
# Isolation: a child's nonzero exit is ignored and never aborts siblings; the dispatcher
# itself always exits 0 (a nonzero UserPromptSubmit hook can block the prompt).
# Scope: additionalContext-only. A feature needing control fields (continue/decision/
# systemMessage) is out of this model — wire it as its own direct settings.json entry.
set -uo pipefail

event="${1:-}"
[[ -z "$event" ]] && exit 0
command -v jq >/dev/null 2>&1 || exit 0   # no jq → silent no-op, never break the session

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
dir="$CFG/hooks/${event}.d"
[[ -d "$dir" ]] || exit 0

payload="$(cat)"

merged=""
for f in "$dir"/*; do
    [[ -e "$f" ]] || continue          # empty dir → literal glob, skip
    [[ -x "$f" ]] || continue
    out="$(printf '%s' "$payload" | "$f" 2>/dev/null)" || true
    [[ -z "$out" ]] && continue
    if [[ -z "$merged" ]]; then
        merged="$out"
    else
        merged="${merged}"$'\n\n'"${out}"
    fi
done

[[ -z "$merged" ]] && exit 0
jq -n --arg e "$event" --arg c "$merged" \
    '{hookSpecificOutput:{hookEventName:$e,additionalContext:$c}}'
exit 0
