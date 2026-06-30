#!/usr/bin/env bash
# Context-efficient backpressure wrapper.
# Source: https://www.humanlayer.dev/blog/context-efficient-backpressure
#
# Success prints one line (✓ + description) and discards the output. Failure
# prints ✗, the command, and the full captured output, so the agent gets
# everything it needs to diagnose — and nothing it doesn't on success.
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
        printf "  \033[32m✓\033[0m %s\n" "$description"
        rm -f "$tmp_file"
        return 0
    fi

    printf "  \033[31m✗\033[0m %s\n" "$description"
    printf "  \033[31mCommand failed:\033[0m %s\n" "$*"
    cat "$tmp_file"
    rm -f "$tmp_file"
    return "$exit_code"
}
