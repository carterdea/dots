#!/usr/bin/env bats

# Tests that verify all source files referenced in install.sh exist

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    DOTFILES_DIR="$(dirname "$DIR")"
}

@test "shell/.zshrc exists" {
    [ -f "$DOTFILES_DIR/shell/.zshrc" ]
}

@test "shell/.zprofile exists" {
    [ -f "$DOTFILES_DIR/shell/.zprofile" ]
}

@test "git/.gitconfig exists" {
    [ -f "$DOTFILES_DIR/git/.gitconfig" ]
}

@test "git/ignore exists" {
    [ -f "$DOTFILES_DIR/git/ignore" ]
}

@test ".claude/settings.json exists" {
    [ -f "$DOTFILES_DIR/.claude/settings.json" ]
}

@test ".codex/config.toml.example exists" {
    [ -f "$DOTFILES_DIR/.codex/config.toml.example" ]
}

@test "agents/AGENTS.md exists" {
    [ -f "$DOTFILES_DIR/agents/AGENTS.md" ]
}

@test "agents/skills directory exists" {
    [ -d "$DOTFILES_DIR/agents/skills" ]
}

@test "agents/pi-packages.txt exists" {
    [ -f "$DOTFILES_DIR/agents/pi-packages.txt" ]
}
