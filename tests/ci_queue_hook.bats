#!/usr/bin/env bats

# Classifier tests for bin/ci-queue-hook. Each case feeds a PreToolUse
# payload through the hook in dry-run mode and asserts the verdict it logs.

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    HOOK="$(dirname "$DIR")/bin/ci-queue-hook"
    LOG="$BATS_TEST_TMPDIR/queue-hook.log"
}

# Prints "ACTION REASON" for a command classified in dry-run mode.
classify() {
    : > "$LOG"
    jq -cn --arg c "$1" '{tool_input:{command:$c}}' |
        CI_QUEUE_HOOK_LOG="$LOG" CI_QUEUE_HOOK_ENFORCE=0 "$HOOK"
    head -1 "$LOG" | awk -F'\t' '{print $2" "$3}'
}

# Prints the hook's stdout (the rewrite JSON, if any) in enforce mode.
enforce() {
    jq -cn --arg c "$1" '{tool_input:{command:$c}}' |
        CI_QUEUE_HOOK_LOG="$LOG" CI_QUEUE_HOOK_ENFORCE=1 "$HOOK"
}

# --- single-file tests must stay out of the queue, kebab-case included ---

@test "single-file test with plain name is file-scoped" {
    [ "$(classify 'bun test src/utils/simple.test.ts')" = "SKIP file-scoped" ]
}

@test "single-file test with kebab-case name is file-scoped" {
    [ "$(classify 'bun run test -- server/routers/migration-batch.test.ts')" = "SKIP file-scoped" ]
}

@test "bare bun test with kebab-case file is file-scoped" {
    [ "$(classify 'bun test src/utils/date-helpers.test.ts')" = "SKIP file-scoped" ]
}

@test "workspace-filtered single-file test is file-scoped" {
    [ "$(classify 'bun run --filter @mmops/api test -- src/routes/internal-cron.test.ts')" = "SKIP file-scoped" ]
}

@test "quoted test path is file-scoped" {
    [ "$(classify "bun run --filter frontend test 'app/routes/_app.agents_.\$id_.edit.test.tsx'")" = "SKIP file-scoped" ]
}

# --- full suites must still queue ---

@test "bare full suite queues" {
    [ "$(classify 'bun run test')" = "QUEUE long-check" ]
}

@test "bare vitest run queues" {
    [ "$(classify 'vitest run')" = "QUEUE long-check" ]
}

@test "pytest suite queues" {
    [ "$(classify 'cd chat-services && uv run pytest -q')" = "QUEUE long-check" ]
}

@test "workspace-filtered full suite queues" {
    [ "$(classify 'bun run --filter mobile test')" = "QUEUE long-check" ]
}

@test "config-file flag value does not count as file scope" {
    [ "$(classify 'vitest run --config vitest.e2e.ts')" = "QUEUE long-check" ]
}

# --- existing skip rules keep working ---

@test "watch mode is skipped" {
    [ "$(classify 'bun run test --watch')" = "SKIP watch-or-server" ]
}

@test "already-queued ci-lock command is skipped" {
    [ "$(classify '~/.local/bin/ci-lock bash -c "bun run test"')" = "SKIP already-queued" ]
}

@test "name-filtered test is skipped" {
    [ "$(classify 'bun test -t "adds tax to total"')" = "SKIP name-filtered" ]
}

# --- enforce mode ---

@test "enforce mode wraps a full suite in ci-lock" {
    out="$(enforce 'bun run test')"
    [[ "$out" == *'ci-lock bash -c'* ]]
}

@test "enforce mode leaves a file-scoped test untouched" {
    out="$(enforce 'bun run test -- server/routers/migration-batch.test.ts')"
    [ -z "$out" ]
}
