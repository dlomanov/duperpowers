#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 || "$1" != "--file" ]]; then
    echo "usage: kv.sh --file <path> <cmd> [args]" >&2
    exit 2
fi

FILE="$2"
CMD="$3"
shift 3

_ensure_file() {
    mkdir -p "$(dirname "$FILE")"
    [[ -f "$FILE" ]] || touch "$FILE"
}

# A TAB in the key would silently corrupt the key<TAB>value format.
_validate_key() {
    local key="$1"
    if [[ "$key" == *$'\t'* || "$key" == *$'\n'* ]]; then
        echo "key must not contain TAB or newline" >&2
        exit 2
    fi
}

# A newline in the value would split the record and inject a phantom key;
# a TAB would shift the value field. Values are counters/flags, so reject
# rather than escape. Spaces are fine (set joins args).
_validate_value() {
    local value="$1"
    if [[ "$value" == *$'\t'* || "$value" == *$'\n'* ]]; then
        echo "value must not contain TAB or newline" >&2
        exit 2
    fi
}

# Each session writes only its own <sid>.state file; Claude Code runs hooks
# sequentially, so there is a single writer per file — no lock needed.
# Atomic temp-file + mv still guarantees no torn reads on crash.

_read_value() {
    [[ -f "$FILE" ]] || { true; return; }
    awk -F'\t' -v k="$1" '$1==k{print substr($0, length(k)+2); exit}' "$FILE"
}

# Atomically rewrite FILE, filtering out key, optionally appending new entry.
# $1=key  $2=action (set|del)  $3=value (set only)
_write() {
    local key="$1" action="$2" value="${3:-}"
    local dir tmp

    _ensure_file

    dir="$(dirname "$FILE")"
    tmp="$(mktemp "$dir/.kv_tmp.XXXXXX")"

    if ! awk -F'\t' -v k="$key" '$1!=k' "$FILE" > "$tmp"; then
        rm -f "$tmp"
        echo "kv: failed to rewrite state file" >&2
        exit 1
    fi
    if [[ "$action" == "set" ]]; then
        printf '%s\t%s\n' "$key" "$value" >> "$tmp"
    fi
    mv "$tmp" "$FILE"
}

# Read-then-write increment; prints new value.
_incr() {
    local key="$1"
    local dir tmp cur new_val

    _ensure_file

    cur="$(awk -F'\t' -v k="$key" '$1==k{print substr($0, length(k)+2); exit}' "$FILE" 2>/dev/null || true)"
    [[ -z "$cur" ]] && cur=0

    # Self-heal: garbage in the counter would otherwise disable incr for the
    # session forever (every retry hits the same bad value).
    [[ "$cur" =~ ^-?[0-9]+$ ]] || cur=0

    new_val=$(( cur + 1 ))
    dir="$(dirname "$FILE")"
    tmp="$(mktemp "$dir/.kv_tmp.XXXXXX")"
    if ! awk -F'\t' -v k="$key" '$1!=k' "$FILE" > "$tmp"; then
        rm -f "$tmp"
        echo "kv: failed to rewrite state file" >&2
        exit 1
    fi
    printf '%s\t%s\n' "$key" "$new_val" >> "$tmp"
    mv "$tmp" "$FILE"
    echo "$new_val"
}

case "$CMD" in
    get)
        [[ $# -eq 1 ]] || { echo "get requires exactly one key" >&2; exit 2; }
        _validate_key "$1"
        [[ -f "$FILE" ]] || exit 0
        _read_value "$1"
        ;;

    set)
        [[ $# -ge 1 ]] || { echo "set requires key and value" >&2; exit 2; }
        key="$1"; shift
        _validate_key "$key"
        _validate_value "$*"
        _write "$key" set "$*"
        ;;

    incr)
        [[ $# -eq 1 ]] || { echo "incr requires exactly one key" >&2; exit 2; }
        _validate_key "$1"
        _incr "$1"
        ;;

    del)
        [[ $# -eq 1 ]] || { echo "del requires exactly one key" >&2; exit 2; }
        _validate_key "$1"
        [[ -f "$FILE" ]] || { _ensure_file; exit 0; }
        _write "$1" del
        ;;

    *)
        echo "unknown command: $CMD" >&2
        exit 2
        ;;
esac
