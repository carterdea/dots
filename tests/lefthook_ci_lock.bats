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
    printf '#!/bin/sh\necho run >> "%s"\n[ -z "$FAKE_STDIN" ] || cat >"$FAKE_STDIN"\n[ -z "$FAKE_SLEEP" ] || { echo $$ >"$FAKE_SLEEP"; sleep 30; }\nexit "${FAKE_EXIT:-0}"\n' "$RUNS" >"$REPO/node_modules/.bin/lefthook"
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

@test "untracked files run even when git status hides them" {
    git config status.showUntrackedFiles no
    "$SHIM" run pre-push
    touch new.test.ts
    "$SHIM" run pre-push
    [ "$(runs)" = 2 ]
}

@test "runs with excluded or selected checks are not recorded" {
    LEFTHOOK_EXCLUDE=tests "$SHIM" run pre-push
    "$SHIM" run pre-push origin git@example.com:r.git --commands lint
    "$SHIM" run pre-push origin git@example.com:r.git
    [ "$(runs)" = 3 ]
}

@test "pre-push refs on stdin reach lefthook" {
    printf 'refs/heads/a 1 refs/heads/a 0\n' | FAKE_STDIN="$BATS_TEST_TMPDIR/stdin" "$SHIM" run pre-push
    [ "$(cat "$BATS_TEST_TMPDIR/stdin")" = 'refs/heads/a 1 refs/heads/a 0' ]
}

@test "terminating the shim stops the queued check" {
    FAKE_SLEEP="$BATS_TEST_TMPDIR/pid" "$SHIM" run pre-push &
    shim=$!
    for _ in {1..200}; do [ ! -s "$BATS_TEST_TMPDIR/pid" ] || break; sleep 0.05; done
    check="$(cat "$BATS_TEST_TMPDIR/pid")"
    kill -TERM "$shim"
    wait "$shim" || true
    for _ in {1..100}; do kill -0 "$check" 2>/dev/null || break; sleep 0.05; done
    ! kill -0 "$check" 2>/dev/null
}

@test "env vars the hook config reads are part of the cache key" {
    printf 'pre-push:\n  commands:\n    a11y:\n      run: test -z "${BASE_URL:-}"\n' >lefthook.yml
    echo lefthook.yml >>.git/info/exclude
    "$SHIM" run pre-push
    BASE_URL=https://example.test "$SHIM" run pre-push
    "$SHIM" run pre-push
    [ "$(runs)" = 2 ]
}

@test "pass records older than 14 days are not trusted" {
    "$SHIM" run pre-push
    touch -t 202001010000 "$XDG_STATE_HOME"/ci-lock/passed/*
    "$SHIM" run pre-push
    [ "$(runs)" = 2 ]
}

@test "editing an ignored hook config runs pre-push again" {
    echo lefthook.yml >>.git/info/exclude
    echo 'pre-push: {}' >lefthook.yml
    "$SHIM" run pre-push
    printf 'pre-push:\n  commands:\n    lint:\n      run: false\n' >lefthook.yml
    "$SHIM" run pre-push
    [ "$(runs)" = 2 ]
}

@test "a failed forced rerun drops the earlier pass" {
    "$SHIM" run pre-push
    CI_LOCK_NO_PASS_CACHE=1 FAKE_EXIT=1 run "$SHIM" run pre-push
    [ "$status" -eq 1 ]
    "$SHIM" run pre-push
    [ "$(runs)" = 3 ]
}

@test "changes inside an ignored submodule still run" {
    SUB="$BATS_TEST_TMPDIR/sub"
    git init -q "$SUB"
    echo a >"$SUB/f"
    git -C "$SUB" add f
    git -C "$SUB" -c user.name=test -c user.email=test@example.com commit -q -m init
    git -c protocol.file.allow=always submodule -q add "$SUB" sub
    git -c user.name=test -c user.email=test@example.com commit -q -m sub
    git config submodule.sub.ignore all
    "$SHIM" run pre-push
    echo b >sub/f
    "$SHIM" run pre-push
    [ "$(runs)" = 2 ]
}
