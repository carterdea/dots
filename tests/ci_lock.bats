#!/usr/bin/env bats

# Tests for bin/ci-lock's duration log and its FIFO queue.

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    CI_LOCK="$(dirname "$DIR")/bin/ci-lock"
    LOG="$BATS_TEST_TMPDIR/ci-lock.log"
    LOCK="$BATS_TEST_TMPDIR/test.lock"
    # Run from a git hook, these would redirect the fixture repositories.
    unset GIT_DIR GIT_COMMON_DIR GIT_WORK_TREE GIT_INDEX_FILE
}

@test "unavailable clock helper does not prevent the check" {
    mkdir "$BATS_TEST_TMPDIR/shims"
    cp "$DIR/fixtures/unavailable-perl.bash" "$BATS_TEST_TMPDIR/shims/perl"
    chmod +x "$BATS_TEST_TMPDIR/shims/perl"
    run env PATH="$BATS_TEST_TMPDIR/shims:$PATH" CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" \
        "$CI_LOCK" touch "$BATS_TEST_TMPDIR/ran"
    [ "$status" -eq 0 ]
    [ -f "$BATS_TEST_TMPDIR/ran" ]
}

@test "zombie ticket owners do not block the queue" {
    perl -e 'my $pid = fork; die $! unless defined $pid; exit 0 unless $pid;
        open my $f, ">", $ARGV[0] or die $!; print $f $pid; close $f;
        sleep 10; waitpid $pid, 0;' "$BATS_TEST_TMPDIR/zombie" &
    supervisor=$!
    for attempt in {1..100}; do
        [ ! -f "$BATS_TEST_TMPDIR/zombie" ] || break
        sleep 0.01
    done
    zombie="$(cat "$BATS_TEST_TMPDIR/zombie")"
    mkdir "$LOCK.q"
    printf '%s\n' "$((($(date +%s) + 100) * 1000))" >"$(printf '%s/%010d-%010d' "$LOCK.q" 1 "$zombie")"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_TIMEOUT=0.3 "$CI_LOCK" true
    kill "$supervisor" 2>/dev/null || true
    wait "$supervisor" 2>/dev/null || true
    [ "$status" -eq 0 ]
}

@test "symlinked queue directories cannot prune unrelated files" {
    mkdir "$BATS_TEST_TMPDIR/unrelated"
    touch "$BATS_TEST_TMPDIR/unrelated/important-999999"
    ln -s "$BATS_TEST_TMPDIR/unrelated" "$LOCK.q"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" "$CI_LOCK" true
    [ -f "$BATS_TEST_TMPDIR/unrelated/important-999999" ]
    [ "$status" -ne 0 ]
}

@test "writable-by-others queue directories are rejected" {
    mkdir "$LOCK.q"
    chmod 777 "$LOCK.q"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" "$CI_LOCK" true
    [ "$status" -ne 0 ]
}

@test "queue scans stop at the first live ticket" {
    mkdir "$LOCK.q"
    first="$(printf '%s/%010d-%010d' "$LOCK.q" 1 "$$")"
    printf '%s\n' "$((($(date +%s) + 100) * 1000))" >"$first"
    later="$LOCK.q/9999999999-0000999999"
    touch "$later"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_TIMEOUT=0.1 "$CI_LOCK" true
    [ "$status" -ne 0 ]
    [ -f "$later" ]
}

@test "reused PID cannot keep an abandoned ticket alive" {
    mkdir "$LOCK.q"
    ticket="$(printf '%s/m%015d-%010d' "$LOCK.q" 1 "$$")"
    printf 'unknown:999999999999999|different process start\n' > "$ticket"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_TIMEOUT=0.3 "$CI_LOCK" true
    [ "$status" -eq 0 ]
    [ ! -e "$ticket" ]
}

@test "queued invocation survives an in-place rewrite of its script" {
    script="$BATS_TEST_TMPDIR/ci-lock"
    cp "$CI_LOCK" "$script"
    exec 8>"$LOCK"
    flock -x 8
    CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_TIMEOUT=5 \
        /bin/bash "$script" touch "$BATS_TEST_TMPDIR/ran" 8>&- \
        >"$BATS_TEST_TMPDIR/output" 2>&1 &
    waiter=$!

    queued=0
    for attempt in {1..100}; do
        if grep -q 'waiting in queue' "$BATS_TEST_TMPDIR/output"; then
            queued=1
            break
        fi
        sleep 0.02
    done
    # Move the remaining program beyond any buffered source, changing the
    # existing inode just as an editor does. An old reader must not run it.
    awk 'BEGIN { for (i=0; i<32768; i++) print ""; print "exit 99" }' >"$script"
    exec 8>&-
    result=0
    wait "$waiter" || result=$?

    [ "$queued" -eq 1 ]
    [ "$result" -eq 0 ]
    [ -f "$BATS_TEST_TMPDIR/ran" ]
    [ "$(awk -F'\t' '{print $5}' "$LOG")" = 0 ]
    [ -z "$(ls -A "$LOCK.q")" ]
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

@test "stopped expired waiter does not block the next caller" {
    exec 8>"$LOCK"
    flock -x 8
    BASH_ENV="$DIR/fixtures/ci_lock_stop.bash" CI_TEST_STOP_MARKER="$BATS_TEST_TMPDIR/stopped" \
        CI_LOCK_LOG=/dev/null CI_LOCK_FILE="$LOCK" CI_LOCK_TIMEOUT=0.2 \
        "$CI_LOCK" true 8>&- >"$BATS_TEST_TMPDIR/stopped-output" 2>&1 &
    stopped=$!
    ready=0
    for attempt in {1..100}; do
        if [ -f "$BATS_TEST_TMPDIR/stopped" ]; then
            ready=1
            break
        fi
        sleep 0.01
    done
    if [ "$ready" -ne 1 ]; then
        kill -CONT "$stopped" 2>/dev/null || true
        kill -TERM "$stopped" 2>/dev/null || true
        wait "$stopped" || true
        return 1
    fi
    # The waiter stops itself before its first timed probe.
    sleep 0.3
    exec 8>&-
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_TIMEOUT=0.2 "$CI_LOCK" true
    kill -CONT "$stopped"
    wait "$stopped" || true
    [ "$ready" -eq 1 ]
    [ "$status" -eq 0 ]
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

@test "wall clock jumps do not expire queued callers" {
    mkdir "$BATS_TEST_TMPDIR/shims"
    cp "$DIR/fixtures/clock-jump-perl.bash" "$BATS_TEST_TMPDIR/shims/perl"
    chmod +x "$BATS_TEST_TMPDIR/shims/perl"
    flock "$LOCK" sh -c 'touch "$1"; sleep 0.5' sh "$BATS_TEST_TMPDIR/ready" &
    holder=$!
    for attempt in {1..100}; do
        [ ! -f "$BATS_TEST_TMPDIR/ready" ] || break
        sleep 0.01
    done
    run env PATH="$BATS_TEST_TMPDIR/shims:$PATH" CI_TEST_REAL_PERL="$(command -v perl)" \
        CI_TEST_CLOCK_MARKER="$BATS_TEST_TMPDIR/clock" \
        CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_TIMEOUT=2 "$CI_LOCK" true
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

# --- heavy-lane slots ---

# Polls for a file for up to 10s; slot holders touch one once they hold a slot,
# so assertions never race a holder that has not started yet.
await() {
    for _ in {1..200}; do
        [ ! -e "$1" ] || return 0
        sleep 0.05
    done
    return 1
}

# Starts a two-slot check in directory $2 that marks $1 once it holds a slot.
hold() {
    (cd "$2" && exec env CI_LOCK_LOG=/dev/null CI_LOCK_FILE="$LOCK" CI_LOCK_SLOTS=2 \
        "$CI_LOCK" sh -c "touch '$1'; sleep 10") &
    holders+=($!)
    await "$1"
}

# A throwaway repository; the identity keeps the commit independent of the
# developer's git config.
make_repo() {
    git init -q "$1"
    git -C "$1" -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m init
}

teardown() {
    [ -z "${holders[*]:-}" ] || kill "${holders[@]}" 2>/dev/null || true
    wait 2>/dev/null || true
}

@test "two slots let a second check run beside the first" {
    hold "$BATS_TEST_TMPDIR/a" "$BATS_TEST_TMPDIR"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_SLOTS=2 CI_LOCK_TIMEOUT=1 "$CI_LOCK" true
    [ "$status" -eq 0 ]
}

@test "a third check waits while both slots are busy" {
    hold "$BATS_TEST_TMPDIR/a" "$BATS_TEST_TMPDIR"
    hold "$BATS_TEST_TMPDIR/b" "$BATS_TEST_TMPDIR"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_SLOTS=2 CI_LOCK_TIMEOUT=1 "$CI_LOCK" true
    [ "$status" -eq 1 ]
}

@test "two checks from one repository never share the slots" {
    make_repo "$BATS_TEST_TMPDIR/repo"
    git -C "$BATS_TEST_TMPDIR/repo" worktree add -q "$BATS_TEST_TMPDIR/wt" 2>/dev/null
    hold "$BATS_TEST_TMPDIR/a" "$BATS_TEST_TMPDIR/repo"
    cd "$BATS_TEST_TMPDIR/wt"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_SLOTS=2 CI_LOCK_TIMEOUT=1 "$CI_LOCK" true
    [ "$status" -eq 1 ]
}

@test "inherited GIT_DIR does not pick the repository lock" {
    make_repo "$BATS_TEST_TMPDIR/repo"
    make_repo "$BATS_TEST_TMPDIR/other"
    hold "$BATS_TEST_TMPDIR/a" "$BATS_TEST_TMPDIR/repo"
    cd "$BATS_TEST_TMPDIR/other"
    run env GIT_DIR="$BATS_TEST_TMPDIR/repo/.git" CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" \
        CI_LOCK_SLOTS=2 CI_LOCK_TIMEOUT=1 "$CI_LOCK" true
    [ "$status" -eq 0 ]
}

@test "a waiter from another repository takes the slot a blocked head cannot use" {
    make_repo "$BATS_TEST_TMPDIR/a-repo"
    make_repo "$BATS_TEST_TMPDIR/b-repo"
    hold "$BATS_TEST_TMPDIR/a-running" "$BATS_TEST_TMPDIR/a-repo"
    # A second A check queues first and stays blocked on A's repository lock.
    (cd "$BATS_TEST_TMPDIR/a-repo" && exec env CI_LOCK_LOG=/dev/null CI_LOCK_FILE="$LOCK" \
        CI_LOCK_SLOTS=2 CI_LOCK_TIMEOUT=10 "$CI_LOCK" true 2>/dev/null) &
    holders+=($!)
    for _ in {1..200}; do
        [ -z "$(ls "$LOCK.q")" ] || break
        sleep 0.05
    done
    [ -n "$(ls "$LOCK.q")" ]
    cd "$BATS_TEST_TMPDIR/b-repo"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_SLOTS=2 CI_LOCK_TIMEOUT=2 "$CI_LOCK" true
    [ "$status" -eq 0 ]
}

@test "a legacy slot-0 holder keeps the second slot closed" {
    # A plain flock on slot 0 stands in for an older ci-lock: it holds the
    # slot but no owner or repository lock.
    flock "$LOCK" sh -c "touch '$BATS_TEST_TMPDIR/legacy'; sleep 10" &
    holders+=($!)
    await "$BATS_TEST_TMPDIR/legacy"
    cd "$BATS_TEST_TMPDIR"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_SLOTS=2 CI_LOCK_TIMEOUT=1 "$CI_LOCK" true
    [ "$status" -eq 1 ]
}

@test "a single-slot caller of the shared lane still takes its repository lock" {
    make_repo "$BATS_TEST_TMPDIR/a-repo"
    make_repo "$BATS_TEST_TMPDIR/b-repo"
    state="$BATS_TEST_TMPDIR/state"
    shared() {
        (cd "$1" && exec env XDG_STATE_HOME="$state" CI_LOCK_LOG=/dev/null \
            "$CI_LOCK" sh -c "touch '$2'; sleep 10") &
    }
    # B takes slot 0, A takes slot 1, then B finishes and frees slot 0.
    shared "$BATS_TEST_TMPDIR/b-repo" "$BATS_TEST_TMPDIR/b"
    b_holder=$!
    await "$BATS_TEST_TMPDIR/b"
    shared "$BATS_TEST_TMPDIR/a-repo" "$BATS_TEST_TMPDIR/a"
    holders+=($!)
    await "$BATS_TEST_TMPDIR/a"
    kill "$b_holder"
    wait "$b_holder" 2>/dev/null || true
    # A single-slot caller from A's repository now finds slot 0 free.
    cd "$BATS_TEST_TMPDIR/a-repo"
    run env XDG_STATE_HOME="$state" CI_LOCK_LOG="$LOG" CI_LOCK_SLOTS=1 CI_LOCK_TIMEOUT=1 "$CI_LOCK" true
    [ "$status" -eq 1 ]
}

@test "a nested run in another repository is refused" {
    make_repo "$BATS_TEST_TMPDIR/a-repo"
    make_repo "$BATS_TEST_TMPDIR/b-repo"
    state="$BATS_TEST_TMPDIR/state"
    # B's own check holds slot 0 and B's repository lock.
    (cd "$BATS_TEST_TMPDIR/b-repo" && exec env XDG_STATE_HOME="$state" CI_LOCK_LOG=/dev/null \
        "$CI_LOCK" sh -c "touch '$BATS_TEST_TMPDIR/b'; sleep 10") &
    holders+=($!)
    await "$BATS_TEST_TMPDIR/b"
    # A's check takes slot 1, then re-enters ci-lock from inside B.
    (cd "$BATS_TEST_TMPDIR/a-repo" && exec env XDG_STATE_HOME="$state" CI_LOCK_LOG=/dev/null \
        "$CI_LOCK" sh -c "cd '$BATS_TEST_TMPDIR/b-repo' && '$CI_LOCK' true; echo \$? >'$BATS_TEST_TMPDIR/nested'") &
    holders+=($!)
    await "$BATS_TEST_TMPDIR/nested"
    [ "$(cat "$BATS_TEST_TMPDIR/nested")" = "1" ]
}

@test "a nested run in another repository is refused even when that repository is free" {
    make_repo "$BATS_TEST_TMPDIR/a-repo"
    make_repo "$BATS_TEST_TMPDIR/b-repo"
    cd "$BATS_TEST_TMPDIR/a-repo"
    run env XDG_STATE_HOME="$BATS_TEST_TMPDIR/state" CI_LOCK_LOG=/dev/null \
        "$CI_LOCK" sh -c "cd '$BATS_TEST_TMPDIR/b-repo' && '$CI_LOCK' true"
    [ "$status" -eq 1 ]
}

@test "a nested run in the same repository reuses the held slot" {
    make_repo "$BATS_TEST_TMPDIR/a-repo"
    state="$BATS_TEST_TMPDIR/state"
    cd "$BATS_TEST_TMPDIR/a-repo"
    run env XDG_STATE_HOME="$state" CI_LOCK_LOG=/dev/null CI_LOCK_TIMEOUT=1 \
        "$CI_LOCK" sh -c "'$CI_LOCK' true"
    [ "$status" -eq 0 ]
}

@test "inherited descriptors the lock never opened reach the command" {
    printf 'from-fd-8' >"$BATS_TEST_TMPDIR/input"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" "$CI_LOCK" sh -c 'cat <&8' 8<"$BATS_TEST_TMPDIR/input"
    [ "$status" -eq 0 ]
    [ "$output" = "from-fd-8" ]
}

@test "a caller's fd 8 survives the shared lane's repository lock" {
    make_repo "$BATS_TEST_TMPDIR/repo"
    printf 'from-fd-8' >"$BATS_TEST_TMPDIR/input"
    cd "$BATS_TEST_TMPDIR/repo"
    run env XDG_STATE_HOME="$BATS_TEST_TMPDIR/state" CI_LOCK_LOG="$LOG" \
        "$CI_LOCK" sh -c 'cat <&8' 8<"$BATS_TEST_TMPDIR/input"
    [ "$status" -eq 0 ]
    [ "$output" = "from-fd-8" ]
}

@test "an inherited ceiling does not hide the repository" {
    make_repo "$BATS_TEST_TMPDIR/repo"
    mkdir -p "$BATS_TEST_TMPDIR/repo/sub/dir"
    hold "$BATS_TEST_TMPDIR/a" "$BATS_TEST_TMPDIR/repo"
    cd "$BATS_TEST_TMPDIR/repo/sub/dir"
    run env GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR/repo/sub" CI_LOCK_LOG="$LOG" \
        CI_LOCK_FILE="$LOCK" CI_LOCK_SLOTS=2 CI_LOCK_TIMEOUT=1 "$CI_LOCK" true
    [ "$status" -eq 1 ]
}

@test "a lock path with marker delimiters still re-enters its own repository" {
    make_repo "$BATS_TEST_TMPDIR/repo"
    cd "$BATS_TEST_TMPDIR/repo"
    run env CI_LOCK_LOG=/dev/null CI_LOCK_FILE="$BATS_TEST_TMPDIR/a|b@c:d.lock" CI_LOCK_SLOTS=2 \
        "$CI_LOCK" "$CI_LOCK" true
    [ "$status" -eq 0 ]
}

@test "a descriptor limit too low for the lock fds runs the command at once" {
    run bash -c "ulimit -n 128; CI_LOCK_LOG='$LOG' CI_LOCK_FILE='$LOCK' CI_LOCK_TIMEOUT=5 '$CI_LOCK' echo ran"
    [ "$status" -eq 0 ]
    [[ "$output" == *"running without the queue"* ]]
    [[ "$output" == *ran* ]]
}

@test "a zombie marker holder does not let a nested call skip the lock" {
    perl -e 'my $pid = fork; die $! unless defined $pid; exit 0 unless $pid;
        open my $f, ">", $ARGV[0] or die $!; print $f $pid; close $f;
        sleep 10; waitpid $pid, 0;' "$BATS_TEST_TMPDIR/zombie" &
    holders+=($!)
    await "$BATS_TEST_TMPDIR/zombie"
    sleep 0.2
    zombie="$(cat "$BATS_TEST_TMPDIR/zombie")"
    flock "$LOCK" sleep 10 &
    holders+=($!)
    sleep 0.3
    cd "$BATS_TEST_TMPDIR"
    run env CI_LOCK_HELD_HEAVY="$LOCK::$zombie" CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" \
        CI_LOCK_TIMEOUT=1 "$CI_LOCK" true
    [ "$status" -eq 1 ]
}

@test "a held marker from before the update is reused, not refused" {
    make_repo "$BATS_TEST_TMPDIR/repo"
    state="$BATS_TEST_TMPDIR/state"
    mkdir -p "$state/ci-lock"
    # The old holder owns the lock; the old marker shape has no repo field.
    flock "$state/ci-lock/heavy.lock" sleep 10 &
    holders+=($!)
    sleep 0.3
    cd "$BATS_TEST_TMPDIR/repo"
    run env XDG_STATE_HOME="$state" CI_LOCK_HELD_HEAVY="$state/ci-lock/heavy.lock:$$" \
        CI_LOCK_LOG=/dev/null CI_LOCK_TIMEOUT=1 "$CI_LOCK" true
    [ "$status" -eq 0 ]
}

@test "a single-slot caller of a private lock shared with two-slot callers takes its repo lock" {
    make_repo "$BATS_TEST_TMPDIR/a-repo"
    make_repo "$BATS_TEST_TMPDIR/b-repo"
    # B takes slot 0, A takes slot 1, then B exits and frees slot 0.
    (cd "$BATS_TEST_TMPDIR/b-repo" && exec env CI_LOCK_LOG=/dev/null CI_LOCK_FILE="$LOCK" CI_LOCK_SLOTS=2 \
        "$CI_LOCK" sh -c "touch '$BATS_TEST_TMPDIR/b'; sleep 10") &
    b_holder=$!
    await "$BATS_TEST_TMPDIR/b"
    hold "$BATS_TEST_TMPDIR/a" "$BATS_TEST_TMPDIR/a-repo"
    kill "$b_holder"
    wait "$b_holder" 2>/dev/null || true
    # A default (single-slot) caller from A now finds slot 0 free.
    cd "$BATS_TEST_TMPDIR/a-repo"
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_TIMEOUT=1 "$CI_LOCK" true
    [ "$status" -eq 1 ]
}

@test "zero-padded slot counts are rejected rather than read as octal" {
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_SLOTS=010 "$CI_LOCK" true
    [ "$status" -eq 64 ]
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_SLOTS=08 "$CI_LOCK" true
    [ "$status" -eq 64 ]
}

@test "an oversized slot count is rejected" {
    run env CI_LOCK_LOG="$LOG" CI_LOCK_FILE="$LOCK" CI_LOCK_SLOTS=99999999999999999999 "$CI_LOCK" true
    [ "$status" -eq 64 ]
}
