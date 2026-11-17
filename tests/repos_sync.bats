#!/usr/bin/env bats

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    REPOS_SYNC="$(dirname "$DIR")/bin/repos-sync"
    unset GIT_DIR GIT_COMMON_DIR GIT_WORK_TREE GIT_INDEX_FILE
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
    export REPOS_SYNC_ROOT="$BATS_TEST_TMPDIR/Sites"
    export REPOS_SYNC_DOTS_DIR="$BATS_TEST_TMPDIR/no-dots"
    ORIGIN="$BATS_TEST_TMPDIR/origin.git"
    SEED="$BATS_TEST_TMPDIR/seed"

    git init -q --bare -b main "$ORIGIN"
    git clone -q "$ORIGIN" "$SEED"
    commit "$SEED" base
    git -C "$SEED" push -q origin main
    mkdir -p "$REPOS_SYNC_ROOT"
    git clone -q "$ORIGIN" "$REPOS_SYNC_ROOT/app"
    APP="$REPOS_SYNC_ROOT/app"
}

commit() {
    echo "$2" > "$1/$2"
    git -C "$1" add "$2"
    git -C "$1" commit -qm "$2"
}

push_upstream_commit() {
    commit "$SEED" upstream
    git -C "$SEED" push -q origin main
}

@test "fast-forwards a clean checkout of main" {
    push_upstream_commit
    run "$REPOS_SYNC"
    [ "$status" -eq 0 ]
    [ "$output" = "app: updated main" ]
    [ -f "$APP/upstream" ]
}

@test "updates main without touching a feature branch checkout" {
    git -C "$APP" switch -qc feature
    echo wip > "$APP/base"
    push_upstream_commit
    run "$REPOS_SYNC"
    [ "$output" = "app: updated main" ]
    [ "$(git -C "$APP" rev-parse main)" = "$(git -C "$SEED" rev-parse HEAD)" ]
    [ "$(git -C "$APP" branch --show-current)" = feature ]
    [ "$(cat "$APP/base")" = wip ]
}

@test "skips main with uncommitted changes" {
    echo wip > "$APP/base"
    push_upstream_commit
    run "$REPOS_SYNC"
    [ "$output" = "app: skipped: uncommitted changes on main" ]
    [ ! -f "$APP/upstream" ]
    [ "$(cat "$APP/base")" = wip ]
}

@test "skips main with local commits" {
    commit "$APP" local
    push_upstream_commit
    run "$REPOS_SYNC"
    [ "$output" = "app: skipped: local main has commits not on origin" ]
    [ -f "$APP/local" ]
}

@test "skips main checked out in another worktree" {
    git -C "$APP" switch -qc feature
    git -C "$APP" worktree add -q "$BATS_TEST_TMPDIR/main-wt" main
    push_upstream_commit
    run "$REPOS_SYNC"
    [ "$output" = "app: skipped: main is checked out in another worktree" ]
}

@test "stays quiet when up to date and fails when a fetch fails" {
    run "$REPOS_SYNC"
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    git -C "$APP" remote set-url origin "$BATS_TEST_TMPDIR/missing.git"
    run "$REPOS_SYNC"
    [ "$status" -ne 0 ]
    [ "$output" = "app: fetch failed" ]
}

@test "runs the dots install script when dots moved" {
    printf '#!/bin/sh\necho "$@" > "%s"\n' "$BATS_TEST_TMPDIR/installed" > "$SEED/install.sh"
    chmod +x "$SEED/install.sh"
    git -C "$SEED" add install.sh
    git -C "$SEED" commit -qm install
    git -C "$SEED" push -q origin main
    run env REPOS_SYNC_DOTS_DIR="$APP" "$REPOS_SYNC"
    [ "$status" -eq 0 ]
    [ "$(cat "$BATS_TEST_TMPDIR/installed")" = "--all" ]
}
