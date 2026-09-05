#!/usr/bin/env bats

# Classifier tests for bin/ci-queue-hook. Each case feeds a PreToolUse
# payload through the hook in dry-run mode and asserts the verdict it logs.

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    HOOK="$(dirname "$DIR")/bin/ci-queue-hook"
    LOG="$BATS_TEST_TMPDIR/queue-hook.log"
    # The hook resolves ci-lock at $HOME/.local/bin/ci-lock; point HOME at a
    # tmpdir holding the repo's copy so enforce-mode tests do not depend on
    # the developer's dotfiles being installed.
    FAKE_HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$FAKE_HOME/.local/bin"
    ln -sf "$(dirname "$DIR")/bin/ci-lock" "$FAKE_HOME/.local/bin/ci-lock"
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
        HOME="$FAKE_HOME" CI_QUEUE_HOOK_LOG="$LOG" CI_QUEUE_HOOK_ENFORCE=1 "$HOOK"
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

# --- read-only commands mentioning heavy words must not queue ---

@test "sed printing a verify script is not queued" {
    [ "$(classify "sed -n '1,240p' scripts/verify-quick.sh")" = "SKIP read-only-tool" ]
}

@test "rg searching for verify:quick is not queued" {
    [ "$(classify "rg -n verify:quick package.json scripts")" = "SKIP read-only-tool" ]
}

@test "gh pr create with suite words in the title is not queued" {
    [ "$(classify "gh pr create --title 'chore(mobile): cap playwright workers'")" = "SKIP read-only-tool" ]
}

@test "piped read-only chain is not queued" {
    [ "$(classify 'git diff --stat | grep test')" = "SKIP read-only-tool" ]
}

@test "cat heredoc writing a test file is not queued" {
    cmd="$(printf "cat > zz-probe.test.ts <<'EOF'\nuv run pytest -q\nEOF")"
    [ "$(classify "$cmd")" = "SKIP read-only-tool" ]
}

@test "heredoc body does not classify the command that writes it" {
    cmd="$(printf "python3 - <<'PY'\nprint('bun run test and pytest')\nPY")"
    [ "$(classify "$cmd")" = "SKIP not-heavy" ]
}

@test "cd into a dir then running the suite still queues" {
    [ "$(classify 'cd app && bun run test')" = "QUEUE long-check" ]
}

# --- typecheck and lint get their own lane, not the heavy one ---

@test "bun run typecheck routes to the check lane" {
    [ "$(classify 'bun run typecheck')" = "QUEUE check-only" ]
}

@test "tsc --noEmit routes to the check lane" {
    [ "$(classify 'bunx tsc --noEmit')" = "QUEUE check-only" ]
}

@test "basedpyright routes to the check lane" {
    [ "$(classify 'cd chat-services && uv run basedpyright chat_service')" = "QUEUE check-only" ]
}

@test "full-repo biome check routes to the check lane" {
    [ "$(classify 'bunx biome check .')" = "QUEUE check-only" ]
}

@test "typecheck combined with a suite stays on the heavy lane" {
    [ "$(classify 'bun run typecheck && bun run test')" = "QUEUE long-check" ]
}

@test "enforce mode puts a check-only command on the check lane" {
    out="$(enforce 'bun run typecheck')"
    [[ "$out" == *'CI_LOCK_LANE=check'* ]]
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

# --- review fixes: flags that do not consume the next argument ---

@test "single-file pytest behind a quiet flag is file-scoped" {
    [ "$(classify 'pytest -q tests/test_one.py')" = "SKIP file-scoped" ]
}

@test "single-file jest behind runInBand is file-scoped" {
    [ "$(classify 'jest --runInBand tests/foo.test.js')" = "SKIP file-scoped" ]
}

# --- review fixes: nested execution is not read-only ---

@test "command substitution running a suite queues" {
    [ "$(classify 'echo "$(bun run test)"')" = "QUEUE long-check" ]
}

@test "find -exec running a suite queues" {
    [ "$(classify 'find . -exec bun run test \;')" = "QUEUE long-check" ]
}

# --- review fixes: a file in one segment does not scope another ---

@test "file in one segment does not excuse a suite in the next" {
    [ "$(classify 'cat src/foo-bar.ts && bun run test')" = "QUEUE long-check" ]
}

# --- review fixes: separators inside quotes do not split segments ---

@test "quoted semicolon in a PR title stays read-only" {
    [ "$(classify "gh pr create --title 'fix playwright; cap workers'")" = "SKIP read-only-tool" ]
}

@test "quoted pipe in an rg pattern stays read-only" {
    [ "$(classify "rg -n 'playwright|cypress' README.md")" = "SKIP read-only-tool" ]
}

# --- review fixes: here-strings and shell heredocs ---

@test "here-string does not swallow the rest of the command" {
    cmd="$(printf "cat <<< note\nbun run test")"
    [ "$(classify "$cmd")" = "QUEUE long-check" ]
}

@test "heredoc fed to bash is executed, so its body still counts" {
    cmd="$(printf "bash <<'EOF'\nbun run test\nEOF")"
    [ "$(classify "$cmd")" = "QUEUE long-check" ]
}

# --- review fixes: log records stay one line ---

@test "multiline command logs a single sanitized record" {
    : > "$LOG"
    cmd="$(printf 'bun run test\nrm -rf docs')"
    jq -cn --arg c "$cmd" '{tool_input:{command:$c}}' |
        CI_QUEUE_HOOK_LOG="$LOG" CI_QUEUE_HOOK_ENFORCE=0 "$HOOK"
    [ "$(wc -l < "$LOG" | tr -d ' ')" = "1" ]
    [ "$(head -1 "$LOG" | awk -F'\t' '{print NF}')" = "4" ]
}

# --- second review round ---

@test "punctuated heredoc delimiter still terminates stripping" {
    cmd="$(printf "cat > x.json <<'END-JSON'\nuv run pytest\nEND-JSON\nbun run test")"
    [ "$(classify "$cmd")" = "QUEUE long-check" ]
}

@test "process substitution running a suite queues" {
    [ "$(classify 'cat <(bun run test)')" = "QUEUE long-check" ]
}

@test "escaped quotes inside double quotes stay one segment" {
    cmd="$(cat <<'EOF'
printf '%s\n' "fix \"x; playwright\""
EOF
)"
    [ "$(classify "$cmd")" = "SKIP read-only-tool" ]
}

@test "biome check with flags before the dot routes to the check lane" {
    [ "$(classify 'bunx biome check --error-on-warnings .')" = "QUEUE check-only" ]
}

@test "typecheck plus an unrecognized command stays on the heavy lane" {
    [ "$(classify 'bun run typecheck && bun run integration')" = "QUEUE long-check" ]
}

# --- third review round ---

@test "pytest --ignore path does not count as file scope" {
    [ "$(classify 'pytest --ignore tests/flaky-test.py')" = "QUEUE long-check" ]
}

@test "heredoc fed to bash -s still counts" {
    cmd="$(printf "bash -s <<'EOF'\nbun run test\nEOF")"
    [ "$(classify "$cmd")" = "QUEUE long-check" ]
}

@test "heredoc fed to an absolute-path shell still counts" {
    cmd="$(printf "/bin/bash <<'EOF'\nbun run test\nEOF")"
    [ "$(classify "$cmd")" = "QUEUE long-check" ]
}

@test "backslash-quoted heredoc delimiter still terminates stripping" {
    cmd="$(printf 'cat <<\\EOF\npytest notes\nEOF\nbun run test')"
    [ "$(classify "$cmd")" = "QUEUE long-check" ]
}

@test "substitution inside an unquoted heredoc body queues" {
    cmd="$(printf '%s\n' 'cat >/dev/null <<EOF' '$(bun run test)' 'EOF')"
    [ "$(classify "$cmd")" = "QUEUE long-check" ]
}

@test "awk system() call is not read-only" {
    [ "$(classify 'awk '"'"'BEGIN{system("bun run test")}'"'"'')" = "QUEUE long-check" ]
}

@test "searching for system( stays read-only" {
    [ "$(classify 'rg -n "system\(" src')" = "SKIP read-only-tool" ]
}

@test "bun run lint routes to the check lane" {
    [ "$(classify 'bun run lint')" = "QUEUE check-only" ]
}

@test "full-repo ruff check routes to the check lane" {
    [ "$(classify 'uv run ruff check .')" = "QUEUE check-only" ]
}

# --- fourth review round: redirections are not separators ---

@test "typecheck with 2>&1 piped to tail routes to the check lane" {
    [ "$(classify 'bun run typecheck 2>&1 | tail -5')" = "QUEUE check-only" ]
}

@test "tsc with both streams redirected routes to the check lane" {
    [ "$(classify 'npx tsc --noEmit >/dev/null 2>&1')" = "QUEUE check-only" ]
}

@test "typecheck with a combined redirection routes to the check lane" {
    [ "$(classify 'bun run typecheck &> out.log')" = "QUEUE check-only" ]
}

# --- fourth review round: browser downloads are not checks ---

@test "playwright install is not queued" {
    [ "$(classify 'bunx playwright install chromium')" = "SKIP not-a-check" ]
}

@test "playwright install-deps is not queued" {
    [ "$(classify 'bunx playwright install-deps')" = "SKIP not-a-check" ]
}

@test "playwright test still queues" {
    [ "$(classify 'bunx playwright test')" = "QUEUE long-check" ]
}

# --- fourth review round: polling loops must not hold the lock ---

@test "until loop polling with sleep is skipped" {
    [ "$(classify 'until ! kill -0 $(pgrep -f "tsc --noEmit" | head -1) 2>/dev/null; do sleep 5; done; echo done')" = "SKIP wait-loop" ]
}

# --- fourth review round: rails suites queue ---

@test "bin/rails test queues" {
    [ "$(classify 'bin/rails test')" = "QUEUE long-check" ]
}

@test "rails system tests queue" {
    [ "$(classify 'bin/rails test:system')" = "QUEUE long-check" ]
}

@test "bundle exec rails test queues" {
    [ "$(classify 'bundle exec rails test')" = "QUEUE long-check" ]
}

@test "rake test queues" {
    [ "$(classify 'rake test')" = "QUEUE long-check" ]
}

@test "rails test:all queues" {
    [ "$(classify 'rails test:all')" = "QUEUE long-check" ]
}

@test "single-file rails test is file-scoped" {
    [ "$(classify 'bin/rails test test/models/donation_test.rb')" = "SKIP file-scoped" ]
}

# --- fourth review round: theme check gets the check lane ---

@test "shopify theme check routes to the check lane" {
    [ "$(classify 'shopify theme check')" = "QUEUE check-only" ]
}

@test "theme check via a package script routes to the check lane" {
    [ "$(classify 'bun run check:theme')" = "QUEUE check-only" ]
}

@test "pgrep for a suite name is read-only" {
    [ "$(classify "pgrep -fc 'vitest|jest|playwright'")" = "SKIP read-only-tool" ]
}

@test "ps listing piped through grep for a runner is read-only" {
    [ "$(classify 'ps -axo pid,command | grep playwright')" = "SKIP read-only-tool" ]
}

@test "suite inside a sleeping loop still queues" {
    [ "$(classify 'while true; do bun test; sleep 1; done')" = "QUEUE long-check" ]
}

@test "suite after a wait loop still queues" {
    [ "$(classify 'until ! kill -0 1234; do sleep 1; done && bun run test')" = "QUEUE long-check" ]
}

@test "quoted loop text does not excuse a suite" {
    [ "$(classify "printf 'while x; do sleep 1; done' > note.txt && bun test")" = "QUEUE long-check" ]
}

@test "versioned playwright install is not a check" {
    [ "$(classify 'bunx playwright@1.55.0 install chromium')" = "SKIP not-a-check" ]
}

@test "newline polling loops skip the queue" {
    [ "$(classify $'until ! pgrep -f playwright\ndo\n sleep 5\ndone')" = "SKIP wait-loop" ]
}

@test "checks in sleeping loop conditions queue" {
    [ "$(classify 'while bun test; do sleep 1; done')" = "QUEUE long-check" ]
    [ "$(classify 'until bun run typecheck; do sleep 1; done')" = "QUEUE check-only" ]
    [ "$(classify 'until bun run typecheck; do sleep 1; done; bun test')" = "QUEUE long-check" ]
}

@test "quoted shell installs do not mask subsequent checks" {
    [ "$(classify "bash -c 'playwright install chromium && playwright test'")" = "QUEUE long-check" ]
    [ "$(classify "bash -c 'playwright install chromium && bun test'")" = "QUEUE long-check" ]
    [ "$(classify "bash -c 'playwright install chromium'")" = "SKIP not-a-check" ]
}
