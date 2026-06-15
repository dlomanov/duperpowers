#!/usr/bin/env bash
# -u catches unbound vars; -o pipefail catches pipe errors; no -e so all tests run
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LW="$SCRIPT_DIR/logwriter.sh"
TESTDATA="$HOME/.claude/scripts/.testdata_logwriter"

# ── Cleanup ────────────────────────────────────────────────────────────────────
cleanup() { rm -rf "$TESTDATA"; }
cleanup
mkdir -p "$TESTDATA"
trap cleanup EXIT

# ── Harness ───────────────────────────────────────────────────────────────────
PASS=0; FAIL=0
pass() { echo "PASS $1"; (( PASS++ )); }
fail() { echo "FAIL $1: $2"; (( FAIL++ )); }

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then pass "$label"
    else fail "$label" "expected $(printf '%q' "$expected"), got $(printf '%q' "$actual")"; fi
}

assert_exit() {
    local label="$1" expected="$2"; shift 2
    local actual
    actual=$("$@" 2>/dev/null); local code=$?
    # Rerun to capture exit code properly
    set +e; "$@" >/dev/null 2>&1; code=$?; set -e
    if [[ "$code" == "$expected" ]]; then pass "$label"
    else fail "$label" "expected exit $expected, got exit $code"; fi
}

# ── Tests ─────────────────────────────────────────────────────────────────────

# T1: append single line → 1 physical line; read --full returns the text
WAL="$TESTDATA/t1/wal.log"
"$LW" --wal "$WAL" append hello world
lines=$(wc -l < "$WAL" | tr -d ' ')
assert_eq "T1a: single physical line" "1" "$lines"
out=$("$LW" --wal "$WAL" read --full | awk -F'\t' '{print $2}')
assert_eq "T1b: read --full returns text" "hello world" "$out"

# T2: multiline text → 1 physical line; round-trips back
WAL="$TESTDATA/t2/wal.log"
MULTILINE=$'line one\nline two'
"$LW" --wal "$WAL" append "$MULTILINE"
lines=$(wc -l < "$WAL" | tr -d ' ')
assert_eq "T2a: multiline stored as 1 physical line" "1" "$lines"
# cut after first tab; the text itself may contain newlines after decode
out=$("$LW" --wal "$WAL" read --full | cut -f2-)
assert_eq "T2b: multiline round-trips" "$MULTILINE" "$out"

# T3: literal backslash round-trips
WAL="$TESTDATA/t3/wal.log"
BSLASH=$'foo\\bar'
"$LW" --wal "$WAL" append "$BSLASH"
out=$("$LW" --wal "$WAL" read --full | awk -F'\t' '{print $2}')
assert_eq "T3: backslash round-trip" "$BSLASH" "$out"

# T4: stdin append when no text args
WAL="$TESTDATA/t4/wal.log"
echo "from stdin" | "$LW" --wal "$WAL" append
out=$("$LW" --wal "$WAL" read --full | awk -F'\t' '{print $2}')
assert_eq "T4: stdin read" "from stdin" "$out"

# T5: literal TAB in text → physical line stays 2 TSV fields; round-trips
WAL="$TESTDATA/t5/wal.log"
TABTEXT=$'col1\tcol2 and more'
"$LW" --wal "$WAL" append "$TABTEXT"
fields=$(awk -F'\t' '{print NF}' "$WAL")
assert_eq "T5a: physical line has exactly 2 fields" "2" "$fields"
out=$("$LW" --wal "$WAL" read --full | cut -f2-)
assert_eq "T5b: embedded TAB round-trips" "$TABTEXT" "$out"

# T6: hash on missing wal → exit 1
WAL="$TESTDATA/t6/missing.log"
set +e; "$LW" --wal "$WAL" hash 2>/dev/null; code=$?; set -e
if [[ "$code" == "1" ]]; then pass "T6: hash missing wal exits 1"
else fail "T6: hash missing wal exits 1" "got exit $code"; fi

# T7: hash changes after append
WAL="$TESTDATA/t7/wal.log"
"$LW" --wal "$WAL" append before
h1=$("$LW" --wal "$WAL" hash)
"$LW" --wal "$WAL" append after
h2=$("$LW" --wal "$WAL" hash)
if [[ "$h1" != "$h2" ]]; then pass "T7: hash changes after append"
else fail "T7: hash changes after append" "hash unchanged: $h1"; fi

# T8: stale — no sum file → exit 0 (stale)
WAL="$TESTDATA/t8/wal.log"
"$LW" --wal "$WAL" append data
set +e; "$LW" --wal "$WAL" stale; code=$?; set -e
if [[ "$code" == "0" ]]; then pass "T8: stale no sum → exit 0"
else fail "T8: stale no sum → exit 0" "got exit $code"; fi

# T9: stale — matching hash + complete structure → exit 1 (fresh)
WAL="$TESTDATA/t9/wal.log"
"$LW" --wal "$WAL" append data
h=$("$LW" --wal "$WAL" hash)
printf 'hash: %s\ntopics: a,b\n\nbody\n' "$h" > "$WAL.sum"
set +e; "$LW" --wal "$WAL" stale; code=$?; set -e
if [[ "$code" == "1" ]]; then pass "T9: stale matching hash → exit 1"
else fail "T9: stale matching hash → exit 1" "got exit $code"; fi

# T9b: header-only .sum (correct hash, no topics line) → exit 0 (stale)
WAL="$TESTDATA/t9b/wal.log"
"$LW" --wal "$WAL" append data
h=$("$LW" --wal "$WAL" hash)
printf 'hash: %s\n' "$h" > "$WAL.sum"
set +e; "$LW" --wal "$WAL" stale; code=$?; set -e
if [[ "$code" == "0" ]]; then pass "T9b: header-only sum → exit 0 (stale)"
else fail "T9b: header-only sum → exit 0 (stale)" "got exit $code"; fi

# T9c: orphaned .sum, WAL missing → exit 0 (stale), no errexit abort
WAL="$TESTDATA/t9c/wal.log"
mkdir -p "$TESTDATA/t9c"
printf 'hash: deadbeef\ntopics: x\n\nbody\n' > "$WAL.sum"
set +e; "$LW" --wal "$WAL" stale 2>/dev/null; code=$?; set -e
if [[ "$code" == "0" ]]; then pass "T9c: orphaned sum, missing wal → exit 0 (stale)"
else fail "T9c: orphaned sum, missing wal → exit 0 (stale)" "got exit $code"; fi

# T10: stale — non-matching hash → exit 0 (stale)
WAL="$TESTDATA/t10/wal.log"
"$LW" --wal "$WAL" append data
echo "hash: 0000000000000000000000000000000000000000000000000000000000000000" > "$WAL.sum"
set +e; "$LW" --wal "$WAL" stale; code=$?; set -e
if [[ "$code" == "0" ]]; then pass "T10: stale wrong hash → exit 0"
else fail "T10: stale wrong hash → exit 0" "got exit $code"; fi

# T10b: read --full on missing wal → exit 1 with clean message
set +e; "$LW" --wal "$TESTDATA/t10/nope.log" read --full 2>/dev/null; code=$?; set -e
if [[ "$code" == "1" ]]; then pass "T10b: read --full missing wal → exit 1"
else fail "T10b: read --full missing wal → exit 1" "got exit $code"; fi

# T11: wal + parent dir auto-created on first append
WAL="$TESTDATA/t11/deep/nested/wal.log"
"$LW" --wal "$WAL" append creation
if [[ -f "$WAL" ]]; then pass "T11: parent dir auto-created"
else fail "T11: parent dir auto-created" "file not found: $WAL"; fi

# T12: BUG 1 repro — C:\nano must NOT decode \n as newline
WAL="$TESTDATA/t12/wal.log"
"$LW" --wal "$WAL" append 'C:\nano'
out=$("$LW" --wal "$WAL" read --full | awk -F'\t' '{print $2}')
assert_eq "T12: C:\\nano round-trips exactly" 'C:\nano' "$out"

# T13: mixed escapes — backslash-n literal, double-backslash, tab char
WAL="$TESTDATA/t13/wal.log"
INPUT=$'regex \\n and \\\\ and \\t'
"$LW" --wal "$WAL" append "$INPUT"
out=$("$LW" --wal "$WAL" read --full | awk -F'\t' '{print $2}')
assert_eq "T13: mixed escape sequences round-trip" "$INPUT" "$out"

# T14: record with real internal newline AND a literal \n together
WAL="$TESTDATA/t14/wal.log"
INPUT=$'real\nnewline and literal \\n backslash-n'
"$LW" --wal "$WAL" append "$INPUT"
lines=$(wc -l < "$WAL" | tr -d ' ')
assert_eq "T14a: internal newline stored as 1 physical line" "1" "$lines"
out=$("$LW" --wal "$WAL" read --full | cut -f2-)
assert_eq "T14b: internal newline + literal \\n round-trips" "$INPUT" "$out"

# T15: multiline text with multiple internal newlines round-trips (BUG 2 coverage)
WAL="$TESTDATA/t15/wal.log"
INPUT=$'alpha\nbeta\ngamma'
"$LW" --wal "$WAL" append "$INPUT"
lines=$(wc -l < "$WAL" | tr -d ' ')
assert_eq "T15a: multiple internal newlines stored as 1 physical line" "1" "$lines"
out=$("$LW" --wal "$WAL" read --full | cut -f2-)
assert_eq "T15b: multiple internal newlines round-trip" "$INPUT" "$out"

# T16: literal \t sequence and real TAB in one record round-trip together
WAL="$TESTDATA/t16/wal.log"
INPUT=$'literal \\t and real\ttab'
"$LW" --wal "$WAL" append "$INPUT"
out=$("$LW" --wal "$WAL" read --full | cut -f2-)
assert_eq "T16: literal \\t + real TAB round-trip" "$INPUT" "$out"

# T17: oversize — wal under LIMIT → exit 1
WAL="$TESTDATA/t17/wal.log"
"$LW" --wal "$WAL" append small
set +e; "$LW" --wal "$WAL" oversize; code=$?; set -e
if [[ "$code" == "1" ]]; then pass "T17: oversize under limit → exit 1"
else fail "T17: oversize under limit → exit 1" "got exit $code"; fi

# T18: oversize — wal over LIMIT → exit 0
WAL="$TESTDATA/t18/wal.log"
mkdir -p "$TESTDATA/t18"
head -c 40000 /dev/zero > "$WAL"
set +e; "$LW" --wal "$WAL" oversize; code=$?; set -e
if [[ "$code" == "0" ]]; then pass "T18: oversize over limit → exit 0"
else fail "T18: oversize over limit → exit 0" "got exit $code"; fi

# T19: oversize — missing wal → exit 1 (not the *) exit-2)
WAL="$TESTDATA/t19/missing.log"
set +e; "$LW" --wal "$WAL" oversize 2>/dev/null; code=$?; set -e
if [[ "$code" == "1" ]]; then pass "T19: oversize missing wal → exit 1"
else fail "T19: oversize missing wal → exit 1" "got exit $code"; fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
