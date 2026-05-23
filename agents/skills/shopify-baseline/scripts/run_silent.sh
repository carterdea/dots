#!/usr/bin/env bash
# Context-efficient backpressure wrapper.
# Source: https://www.humanlayer.dev/blog/context-efficient-backpressure
#
# Success prints one line. Failure prints the full captured output.
#
# Usage:
#   source scripts/run_silent.sh
#   run_silent "theme check" bun run check:theme

run_silent() {
    local description="$1"
    shift
    local tmp_file
    tmp_file=$(mktemp)

    if (set -o pipefail; "$@") > "$tmp_file" 2>&1; then
        printf "  \033[32m✓\033[0m %s\n" "$description"
        rm -f "$tmp_file"
        return 0
    fi

    local exit_code=$?
    printf "  \033[31m✗\033[0m %s\n" "$description"
    cat "$tmp_file"
    rm -f "$tmp_file"
    return "$exit_code"
}
