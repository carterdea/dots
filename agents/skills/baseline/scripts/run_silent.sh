#!/usr/bin/env bash
# Context-efficient backpressure wrapper.
# Source: https://www.humanlayer.dev/blog/context-efficient-backpressure
#
# Prints a single checkmark on success, full captured output on failure.
# Keeps agent context lean: success = "✓", failure = everything it needs to debug.
#
# Usage:
#   source scripts/run_silent.sh
#   run_silent "biome lint"      "bun run lint"
#   run_silent "typecheck"       "bun run typecheck"
#   run_silent "vitest changed"  "bun run test --changed"

set -o pipefail

run_silent() {
    local description="$1"
    local command="$2"
    local tmp_file
    tmp_file=$(mktemp)
    if eval "$command" > "$tmp_file" 2>&1; then
        printf "  \033[32m✓\033[0m %s\n" "$description"
        rm -f "$tmp_file"
        return 0
    else
        local exit_code=$?
        printf "  \033[31m✗\033[0m %s\n" "$description"
        cat "$tmp_file"
        rm -f "$tmp_file"
        return $exit_code
    fi
}
