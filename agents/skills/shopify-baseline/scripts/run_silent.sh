#!/usr/bin/env bash
# Context-efficient backpressure wrapper.
# Source: https://www.humanlayer.dev/blog/context-efficient-backpressure
#
# Success prints one line (✓ + description) and discards the output. Failure
# prints ✗, the command, and the full captured output, so the agent gets
# everything it needs to diagnose — and nothing it doesn't on success.
# A check that opts out (exits 0 after echoing "skipped: …", e.g. no preview URL
# or no src/) prints a distinct ⊘ status so a skipped scan never reads as a pass.
# Set VERBOSE=1 to stream raw output live (human escape hatch).
#
# Usage:
#   source scripts/run_silent.sh
#   run_silent "theme check" bun run check:theme

VERBOSE="${VERBOSE:-0}"

run_silent() {
    local description="$1"
    shift

    if [ "$VERBOSE" = "1" ]; then
        printf "  → %s\n" "$*"
        "$@"
        return $?
    fi

    local tmp_file
    tmp_file=$(mktemp)
    local exit_code=0
    "$@" > "$tmp_file" 2>&1 || exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
        # A check that opts out echoes "skipped: <reason>" and exits 0. Surface
        # that as its own status so an unrun scan never masquerades as a pass.
        # bun/pnpm print a run banner before the script's own output, so the
        # "skipped:" line isn't necessarily first — scan the whole capture.
        local skip_line
        if skip_line=$(grep -im1 '^skipped:' "$tmp_file"); then
            printf "  \033[33m⊘\033[0m %s (%s)\n" "$description" "$skip_line"
            rm -f "$tmp_file"
            return 0
        fi
        printf "  \033[32m✓\033[0m %s\n" "$description"
        rm -f "$tmp_file"
        return 0
    fi

    printf "  \033[31m✗\033[0m %s\n" "$description"
    # Redact secret-looking args (e.g. shopify --password "$SHOPIFY_CLI_THEME_TOKEN")
    # so a failing command can't leak a token into logs/chat.
    local shown
    shown=$(printf '%s' "$*" | sed -E 's/(--(password|token|secret)[ =])[^ ]+/\1***/g; s/shptka_[A-Za-z0-9]+/shptka_***/g')
    printf "  \033[31mCommand failed:\033[0m %s\n" "$shown"
    cat "$tmp_file"
    rm -f "$tmp_file"
    return "$exit_code"
}
