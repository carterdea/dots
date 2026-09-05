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

@test "ci-lock prunes an expired ticket even if its pid is alive" {
    mkdir -p "$LOCK.q"
    # A ticket stamped an hour ago, naming this test's own (live) shell.
    printf '1\n' > "$(printf '%s/%010d-%010d' "$LOCK.q" "$(( $(date +%s) - 3600 ))" "$$")"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_TIMEOUT=2 "$CI_LOCK" true
    [ "$status" -eq 0 ]
    [ -z "$(ls -A "$LOCK.q")" ]
}

@test "short fractional timeout preserves an older live ticket with a longer deadline" {
    mkdir -p "$LOCK.q"
    ticket="$(printf '%s/%010d-%010d' "$LOCK.q" "$(( $(date +%s) - 120 ))" "$$")"
    printf '%s\n' "$(( ($(date +%s) + 1800) * 1000 ))" > "$ticket"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_TIMEOUT=0.2 "$CI_LOCK" true
    [ "$status" -eq 1 ]
    [[ "$output" == *'timed out after 0.2s'* ]]
    [ -e "$ticket" ]
    [ "$(awk -F'\t' '{print $5}' "$LOG")" = timeout ]
}

@test "zero timeout acquires a free lock and publishes a ticket first" {
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    real_flock="$(command -v flock)"
    # The shim observes ticket publication at the first acquisition attempt.
    printf '#!/bin/bash\ncompgen -G "$CI_LOCK_FILE.q/*" >/dev/null || exit 70\nexec "%s" "$@"\n' \
        "$real_flock" > "$BATS_TEST_TMPDIR/bin/flock"
    chmod +x "$BATS_TEST_TMPDIR/bin/flock"
    run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" \
        CI_LOCK_TIMEOUT=0 "$CI_LOCK" true
    [ "$status" -eq 0 ]
    [ -z "$(ls -A "$LOCK.q")" ]
}

@test "fractional timeout waits for a contended lock" {
    flock "$LOCK" sh -c 'touch "$1"; sleep 0.4' sh "$BATS_TEST_TMPDIR/ready" &
    holder=$!
    for attempt in {1..100}; do
        [ ! -f "$BATS_TEST_TMPDIR/ready" ] || break
        sleep 0.01
    done
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_TIMEOUT=0.8 "$CI_LOCK" true
    wait "$holder"
    [ "$status" -eq 0 ]
}

@test "signal between child launch and PID assignment keeps the wrapper waiting" {
    # DEBUG delivers TERM in the launch window without a timing race.
    run env BASH_ENV="$DIR/fixtures/ci_lock_signal.bash" CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" \
        "$CI_LOCK" sleep 1
    # Bash may receive TERM before exec resets the child's inherited traps.
    # Either way the wrapper must reap the child and record its exit.
    [[ "$status" -eq 0 || "$status" -eq 143 ]]
    [ "$(awk -F'\t' '{print $5}' "$LOG")" = "$status" ]
    flock -n "$LOCK" true
}
