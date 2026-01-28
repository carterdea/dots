#!/usr/bin/env bats

# Tests for install.sh

setup() {
    # Get the directory containing this test file
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    DOTFILES_DIR="$(dirname "$DIR")"
    INSTALL_SCRIPT="$DOTFILES_DIR/install.sh"
}

@test "install.sh exists and is executable" {
    [ -f "$INSTALL_SCRIPT" ]
    [ -x "$INSTALL_SCRIPT" ]
}

@test "install.sh --help exits successfully" {
    run "$INSTALL_SCRIPT" --help
    [ "$status" -eq 0 ]
}

@test "install.sh --dry-run exits successfully" {
    run "$INSTALL_SCRIPT" --dry-run --all
    [ "$status" -eq 0 ]
}

@test "install.sh --dry-run --shell shows shell files" {
    run "$INSTALL_SCRIPT" --dry-run --shell
    [ "$status" -eq 0 ]
    [[ "$output" == *".zshrc"* ]]
}

@test "install.sh --dry-run --claude shows claude config" {
    run "$INSTALL_SCRIPT" --dry-run --claude
    [ "$status" -eq 0 ]
    [[ "$output" == *".claude"* ]]
}

@test "install.sh --dry-run --codex shows codex config" {
    run "$INSTALL_SCRIPT" --dry-run --codex
    [ "$status" -eq 0 ]
    [[ "$output" == *".codex"* ]]
}
