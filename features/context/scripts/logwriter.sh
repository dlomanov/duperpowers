#!/usr/bin/env bash
set -euo pipefail

LIMIT=32768

usage() {
    echo "Usage: logwriter.sh --wal <path> <cmd> [args]" >&2
    echo "Commands: append [text...] | read --full | hash | stale [sum-path] | oversize" >&2
    exit 2
}

[[ $# -lt 2 ]] && usage
[[ "$1" != "--wal" ]] && usage

WAL="$2"; shift 2
[[ $# -eq 0 ]] && usage
CMD="$1"; shift

# Escape: backslash first, then TAB/newline — order is critical for reversibility.
# TAB must be escaped so every physical line stays exactly two TSV fields.
escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

# Single-pass awk decoder: avoids the two-pass sed ordering bug (\\n vs \n ambiguity)
# and avoids command-substitution which strips trailing newlines.
decode_records() {
    awk -F'\t' '{
        ts = $1
        rest = substr($0, length(ts) + 2)
        out = ""; n = length(rest)
        for (i = 1; i <= n; i++) {
            c = substr(rest, i, 1)
            if (c == "\\" && i < n) {
                d = substr(rest, i + 1, 1)
                if (d == "n")  { out = out "\n"; i++ }
                else if (d == "t") { out = out "\t"; i++ }
                else if (d == "\\") { out = out "\\"; i++ }
                else { out = out c }
            } else out = out c
        }
        print ts "\t" out
    }'
}

sha_of() {
    if command -v shasum &>/dev/null; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        sha256sum "$1" | awk '{print $1}'
    fi
}

case "$CMD" in
    append)
        mkdir -p "$(dirname "$WAL")"
        if [[ $# -eq 0 ]]; then
            text=$(cat)
        else
            text="$*"
        fi
        ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        escaped=$(escape "$text")
        # O_APPEND writes are atomic for records under PIPE_BUF; single-writer per session
        printf '%s\t%s\n' "$ts" "$escaped" >> "$WAL"
        ;;

    read)
        [[ "${1:-}" == "--full" ]] || { echo "read requires --full" >&2; exit 2; }
        [[ -f "$WAL" ]] || { echo "wal not found: $WAL" >&2; exit 1; }
        # NOTE: decoded output is human-readable ONLY, not machine-reparseable back
        # into records — once decoded, bodies may contain real newlines/TABs, so the
        # per-record physical-line/TSV-field boundaries are no longer recoverable.
        decode_records < "$WAL"
        ;;

    hash)
        if [[ ! -f "$WAL" ]]; then
            echo "wal not found: $WAL" >&2
            exit 1
        fi
        sha_of "$WAL"
        ;;

    stale)
        # Orphaned .sum without its WAL must read STALE, not abort via errexit
        [[ -f "$WAL" ]] || exit 0
        SUM="${1:-${WAL}.sum}"
        if [[ ! -f "$SUM" ]]; then
            exit 0  # missing sum → stale
        fi
        first_line=$(head -n1 "$SUM")
        if [[ "$first_line" != hash:\ * ]]; then
            exit 0  # malformed sum → stale
        fi
        # A killed reader can leave a header-only .sum whose hash still matches;
        # require the topics line so a body-less cache never reads FRESH.
        second_line=$(sed -n '2p' "$SUM")
        if [[ "$second_line" != topics:* ]]; then
            exit 0  # structurally incomplete sum → stale
        fi
        stored_hash="${first_line#hash: }"
        current_hash=$(sha_of "$WAL")
        if [[ "$stored_hash" == "$current_hash" ]]; then
            exit 1  # hashes match → fresh
        fi
        exit 0  # hashes differ → stale
        ;;

    oversize) [[ -f "$WAL" ]] || exit 1; [[ $(wc -c < "$WAL") -gt "$LIMIT" ]] && exit 0 || exit 1 ;;

    *)
        echo "Unknown command: $CMD" >&2
        exit 2
        ;;
esac
