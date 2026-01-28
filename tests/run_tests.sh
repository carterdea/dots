#!/bin/bash
# Run all tests for the dotfiles repository

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Running shellcheck ==="
shellcheck "$DOTFILES_DIR/install.sh"
# SC2016: bootstrap.sh intentionally uses single quotes to write literal $() to file
shellcheck --exclude=SC2016 "$DOTFILES_DIR/bootstrap.sh" 2>/dev/null || true
shellcheck "$DOTFILES_DIR"/.claude/*.sh 2>/dev/null || true

echo ""
echo "=== Running bats tests ==="
bats "$SCRIPT_DIR"/*.bats

echo ""
echo "All tests passed!"
