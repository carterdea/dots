#!/usr/bin/env bats

# Tests for bin/ci-lock's duration log and its FIFO queue.

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

@test "ci-lock logs a wait that timed out" {
    # The holder logs elsewhere, so $LOG holds only the timed-out wait.
    CI_LOCK_LOG=/dev/null CI_LOCK_FILE="$LOCK" "$CI_LOCK" sleep 5 &
    holder=$!
    sleep 0.5

    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_TIMEOUT=1 "$CI_LOCK" true
    [ "$status" -eq 1 ]

    kill "$holder" 2>/dev/null || true
    wait "$holder" 2>/dev/null || true

    line="$(head -1 "$LOG")"
    [ "$(printf '%s' "$line" | awk -F'\t' '{print NF}')" = "6" ]
    [ "$(printf '%s' "$line" | awk -F'\t' '{print $4}')" = "0" ]
    [ "$(printf '%s' "$line" | awk -F'\t' '{print $5}')" = "timeout" ]
}

@test "ci-lock hands the lock over in arrival order" {
    for round in 1 2 3; do
        lock="$BATS_TEST_TMPDIR/fifo-$round.lock"
        order="$BATS_TEST_TMPDIR/order-$round"
        : >"$order"

        CI_LOCK_LOG=/dev/null CI_LOCK_FILE="$lock" "$CI_LOCK" sleep 3 &
        holder=$!
        sleep 0.5

        waiters=()
        for name in A B C; do
            CI_LOCK_LOG=/dev/null CI_LOCK_FILE="$lock" CI_LOCK_TIMEOUT=30 \
                "$CI_LOCK" sh -c "echo $name >>'$order'" 2>/dev/null &
            waiters+=($!)
            sleep 0.5
        done

        wait "$holder"
        for waiter in "${waiters[@]}"; do wait "$waiter"; done

        [ "$(tr '\n' ' ' <"$order")" = "A B C " ]
    done
}

@test "ci-lock prunes a ticket whose owner is gone" {
    queue="$BATS_TEST_TMPDIR/stale.lock.q"
    mkdir -p "$queue"
    : >"$queue/0000000001-2147483000"

    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$BATS_TEST_TMPDIR/stale.lock" \
        CI_LOCK_TIMEOUT=2 "$CI_LOCK" true
    [ "$status" -eq 0 ]
    [ ! -e "$queue/0000000001-2147483000" ]
}

@test "ci-lock leaves no ticket behind after a run" {
    CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" "$CI_LOCK" true
    [ -z "$(ls -A "$LOCK.q")" ]
}
