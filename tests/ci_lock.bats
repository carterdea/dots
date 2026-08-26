#!/usr/bin/env bats

# Tests for bin/ci-lock's duration log.

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    CI_LOCK="$(dirname "$DIR")/bin/ci-lock"
    LOG="$BATS_TEST_TMPDIR/ci-lock.log"
    LOCK="$BATS_TEST_TMPDIR/test.lock"
}

@test "ci-lock logs lane, wait, run, exit, and command" {
    CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_LANE=heavy "$CI_LOCK" true
    [ -f "$LOG" ]
    line="$(head -1 "$LOG")"
    [ "$(printf '%s' "$line" | awk -F'\t' '{print NF}')" = "6" ]
    [ "$(printf '%s' "$line" | awk -F'\t' '{print $2}')" = "heavy" ]
    [ "$(printf '%s' "$line" | awk -F'\t' '{print $5}')" = "0" ]
    [[ "$line" == *true ]]
}

@test "ci-lock log records a nonzero exit and preserves it" {
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" "$CI_LOCK" bash -c 'exit 3'
    [ "$status" -eq 3 ]
    [ "$(head -1 "$LOG" | awk -F'\t' '{print $5}')" = "3" ]
}

@test "ci-lock log keeps a multiline command to one six-field record" {
    CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$BATS_TEST_TMPDIR/l.lock" "$CI_LOCK" bash -c "$(printf 'true\ntrue')"
    [ "$(wc -l < "$LOG" | tr -d ' ')" = "1" ]
    [ "$(head -1 "$LOG" | awk -F'\t' '{print NF}')" = "6" ]
}
