#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KV="$SCRIPT_DIR/kv.sh"
TESTDATA="$SCRIPT_DIR/.testdata_kv"

# Clean slate before and after
rm -rf "$TESTDATA"
trap 'rm -rf "$TESTDATA"' EXIT
mkdir -p "$TESTDATA"

PASS=0
FAIL=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo "PASS: $desc"
        PASS=$(( PASS + 1 ))
    else
        echo "FAIL: $desc"
        echo "      expected: $(printf '%q' "$expected")"
        echo "      actual:   $(printf '%q' "$actual")"
        FAIL=$(( FAIL + 1 ))
    fi
}

assert_exit() {
    local desc="$1" expected_code="$2"
    shift 2
    local actual_code=0
    "$@" >/dev/null 2>&1 || actual_code=$?
    if [[ "$actual_code" == "$expected_code" ]]; then
        echo "PASS: $desc"
        PASS=$(( PASS + 1 ))
    else
        echo "FAIL: $desc"
        echo "      expected exit: $expected_code"
        echo "      actual exit:   $actual_code"
        FAIL=$(( FAIL + 1 ))
    fi
}

assert_exit_with_output() {
    local desc="$1" expected_code="$2" expected_out="$3"
    shift 3
    local actual_out actual_code=0
    actual_out=$("$@" 2>/dev/null) || actual_code=$?
    if [[ "$actual_code" == "$expected_code" && "$actual_out" == "$expected_out" ]]; then
        echo "PASS: $desc"
        PASS=$(( PASS + 1 ))
    else
        echo "FAIL: $desc"
        echo "      expected exit=$expected_code out=$(printf '%q' "$expected_out")"
        echo "      actual   exit=$actual_code   out=$(printf '%q' "$actual_out")"
        FAIL=$(( FAIL + 1 ))
    fi
}

DB="$TESTDATA/store.db"

# 1. get on missing key → empty output, exit 0
out=$("$KV" --file "$DB" get missing_key)
assert_eq "get missing key returns empty" "" "$out"

# 2. set then get → returns value
"$KV" --file "$DB" set mykey myvalue
out=$("$KV" --file "$DB" get mykey)
assert_eq "set then get returns value" "myvalue" "$out"

# 3. set with spaces in value → get returns full value
"$KV" --file "$DB" set spaced "hello world foo"
out=$("$KV" --file "$DB" get spaced)
assert_eq "set with spaces in value" "hello world foo" "$out"

# 4. set overwrite → get returns new value
"$KV" --file "$DB" set mykey newvalue
out=$("$KV" --file "$DB" get mykey)
assert_eq "set overwrite returns new value" "newvalue" "$out"

# 5. incr on missing key → prints 1
out=$("$KV" --file "$DB" incr counter)
assert_eq "incr on missing key prints 1" "1" "$out"

# 6. incr twice → prints 2
out=$("$KV" --file "$DB" incr counter)
assert_eq "incr twice prints 2" "2" "$out"

# 7. incr on non-integer value → self-heals: resets to 0, prints 1
"$KV" --file "$DB" set badval "notanumber"
out=$("$KV" --file "$DB" incr badval 2>/dev/null)
assert_eq "incr on non-integer self-heals to 1" "1" "$out"

# 8. del removes key → subsequent get empty
"$KV" --file "$DB" set todel "gone"
"$KV" --file "$DB" del todel
out=$("$KV" --file "$DB" get todel)
assert_eq "del removes key, get returns empty" "" "$out"

# 9. multiple keys coexist
DB2="$TESTDATA/multi.db"
"$KV" --file "$DB2" set keyA valueA
"$KV" --file "$DB2" set keyB valueB
outA=$("$KV" --file "$DB2" get keyA)
outB=$("$KV" --file "$DB2" get keyB)
assert_eq "multi-key: keyA unaffected by keyB" "valueA" "$outA"
assert_eq "multi-key: keyB readable" "valueB" "$outB"

# 10. file + parent dir auto-created on first write
DEEP="$TESTDATA/deep/nested/dir/store.db"
"$KV" --file "$DEEP" set init ok
if [[ -f "$DEEP" ]]; then
    echo "PASS: file and parent dirs auto-created"
    PASS=$(( PASS + 1 ))
else
    echo "FAIL: file and parent dirs auto-created"
    FAIL=$(( FAIL + 1 ))
fi

# 11. key with dots (primary production use case)
DB3="$TESTDATA/dots.db"
"$KV" --file "$DB3" set context.prompt_count 42
out=$("$KV" --file "$DB3" get context.prompt_count)
assert_eq "dot-namespaced key: set then get" "42" "$out"

# 12. key containing literal ] and * must not corrupt or cross-match
DB4="$TESTDATA/special.db"
"$KV" --file "$DB4" set 'a.b]c' 5
"$KV" --file "$DB4" set 'a.bXc' 99
out=$("$KV" --file "$DB4" get 'a.b]c')
assert_eq "key with literal ]: correct value returned" "5" "$out"
out=$("$KV" --file "$DB4" get 'a.bXc')
assert_eq "key a.bXc not matched by a.b]c lookup" "99" "$out"

# 13. value containing spaces still works (belt-and-suspenders: also tested in test 3)
DB5="$TESTDATA/spaces.db"
"$KV" --file "$DB5" set mykey "hello world"
out=$("$KV" --file "$DB5" get mykey)
assert_eq "value with spaces preserved" "hello world" "$out"

# 14. key with TAB in it → exit 2
TAB=$'\t'
actual_code=0
"$KV" --file "$DB" set "bad${TAB}key" value >/dev/null 2>&1 || actual_code=$?
if [[ "$actual_code" == "2" ]]; then
    echo "PASS: set with TAB in key exits 2"
    PASS=$(( PASS + 1 ))
else
    echo "FAIL: set with TAB in key exits 2"
    echo "      actual exit: $actual_code"
    FAIL=$(( FAIL + 1 ))
fi

# 15. empty value: set then get returns empty (no crash)
"$KV" --file "$DB" set emptyval ''
out=$("$KV" --file "$DB" get emptyval)
assert_eq "empty value: get returns empty string without crash" "" "$out"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
