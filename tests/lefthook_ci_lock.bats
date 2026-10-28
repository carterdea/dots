#!/usr/bin/env bats

# Tests for bin/lefthook-ci-lock's pre-push pass cache.

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    SHIM="$(dirname "$DIR")/bin/lefthook-ci-lock"
    unset GIT_DIR GIT_COMMON_DIR GIT_WORK_TREE GIT_INDEX_FILE "${!CI_LOCK_@}"
    export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
    export CI_LOCK_FILE="$BATS_TEST_TMPDIR/heavy.lock"
    export CI_LOCK_LOG="$BATS_TEST_TMPDIR/ci-lock.log"
    RUNS="$BATS_TEST_TMPDIR/runs"
    REPO="$BATS_TEST_TMPDIR/repo"
    git init -q "$REPO"
    mkdir -p "$REPO/node_modules/.bin"
    printf '#!/bin/sh\necho run >> "%s"\nexit "${FAKE_EXIT:-0}"\n' "$RUNS" >"$REPO/node_modules/.bin/lefthook"
    chmod +x "$REPO/node_modules/.bin/lefthook"
    echo node_modules >"$REPO/.gitignore"
    echo one >"$REPO/file"
    git -C "$REPO" add .gitignore file
    git -C "$REPO" -c user.name=test -c user.email=test@example.com commit -q -m init
    cd "$REPO"
}

runs() { [ -f "$RUNS" ] && wc -l <"$RUNS" | tr -d ' ' || echo 0; }

@test "a tree that already passed pre-push is skipped" {
    "$SHIM" run pre-push
    run "$SHIM" run pre-push
    [ "$status" -eq 0 ]
    [ "$(runs)" = 1 ]
    [[ "$output" == *"already passed"* ]]
    [[ "$(tail -1 "$CI_LOCK_LOG")" == *$'\tcached\t'* ]]
}

@test "a changed tree runs pre-push again" {
    "$SHIM" run pre-push
    echo two >file
    git -c user.name=test -c user.email=test@example.com commit -qam change
    "$SHIM" run pre-push
    [ "$(runs)" = 2 ]
}

@test "a failed run is not recorded" {
    FAKE_EXIT=1 run "$SHIM" run pre-push
    [ "$status" -eq 1 ]
    "$SHIM" run pre-push
    [ "$(runs)" = 2 ]
}

@test "uncommitted changes always run and record nothing" {
    echo dirty >file
    "$SHIM" run pre-push
    git checkout -q file
    "$SHIM" run pre-push
    [ "$(runs)" = 2 ]
}

@test "untracked files always run" {
    "$SHIM" run pre-push
    touch new.test.ts
    "$SHIM" run pre-push
    [ "$(runs)" = 2 ]
}

@test "CI_LOCK_NO_PASS_CACHE forces a rerun" {
    "$SHIM" run pre-push
    CI_LOCK_NO_PASS_CACHE=1 "$SHIM" run pre-push
    [ "$(runs)" = 2 ]
}

@test "pre-commit is never cached" {
    "$SHIM" run pre-commit
    "$SHIM" run pre-commit
    [ "$(runs)" = 2 ]
}
