#!/usr/bin/env bash
# Canonical quality-check entry point. Routes every check through run_silent so
# a clean run is one line per check and only failures print their full output.
# Run: bash scripts/check.sh  (VERBOSE=1 streams raw output live)
set -uo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=scripts/run_silent.sh
source scripts/run_silent.sh

if [ -f pnpm-lock.yaml ]; then run="pnpm run"; else run="bun run"; fi

status=0
run_silent "theme check"    $run check:theme     || status=1
run_silent "biome"          $run check:biome     || status=1
run_silent "typecheck"      $run check:type      || status=1
run_silent "dead code"      $run check:dead-code || status=1
run_silent "vitest"         $run check:test      || status=1
run_silent "playwright axe" $run check:a11y      || status=1
exit "$status"
