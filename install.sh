#!/usr/bin/env bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Flags
DRY_RUN=false
BACKUP=true
INSTALL_ALL=false
INSTALL_SHELL=false
INSTALL_GIT=false
INSTALL_CONFIG=false
INSTALL_SSH=false
INSTALL_AGENTS=false
INSTALL_CLAUDE=false
INSTALL_CODEX=false
INSTALL_CURSOR=false
INSTALL_CURSOR_PROJECT=false

# Helper functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_usage() {
    cat << EOF
Usage: ./install.sh [OPTIONS]

Install dotfiles with symlinks.

OPTIONS:
    --all           Install all dotfiles
    --shell         Install shell configurations (.zshrc, .bashrc, etc.)
    --git           Install git configurations
    --config        Install tool configs (ripgrep, gh, ghostty)
    --ssh           Install SSH config
    --agents        Install Claude Code agents config (legacy, use --claude)
    --claude        Install prompts/skills to Claude Code (~/.claude)
    --codex         Install prompts/skills to Codex (~/.codex)
    --cursor        Install prompts to Cursor global (~/.cursor)
    --cursor-project Install prompts to Cursor project (.cursor)
    --no-backup     Skip backing up existing files
    --dry-run       Show what would be done without making changes
    -h, --help      Show this help message

EXAMPLES:
    ./install.sh --all                  # Install everything
    ./install.sh --shell --git          # Install only shell and git configs
    ./install.sh --all --dry-run        # Preview what would be installed

EOF
}

backup_file() {
    local file=$1
    if [[ -e "$file" ]] && [[ ! -L "$file" ]]; then
        if [[ "$BACKUP" == true ]]; then
            mkdir -p "$BACKUP_DIR"
            local backup_path="$BACKUP_DIR/$(basename "$file")"
            if [[ "$DRY_RUN" == true ]]; then
                info "[DRY RUN] Would backup: $file -> $backup_path"
            else
                cp -r "$file" "$backup_path"
                info "Backed up: $file -> $backup_path"
            fi
        fi
    fi
}

create_symlink() {
    local source=$1
    local target=$2

    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY RUN] Would symlink: $target -> $source"
        return
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"

    # Remove existing file/symlink
    if [[ -L "$target" ]]; then
        rm "$target"
    elif [[ -e "$target" ]]; then
        backup_file "$target"
        rm -rf "$target"
    fi

    # Create symlink
    ln -s "$source" "$target"
    info "Linked: $target -> $source"
}

install_shell() {
    info "Installing shell configurations..."
    create_symlink "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"
    create_symlink "$DOTFILES_DIR/shell/.zprofile" "$HOME/.zprofile"
    create_symlink "$DOTFILES_DIR/shell/.bashrc" "$HOME/.bashrc"
    create_symlink "$DOTFILES_DIR/shell/.bash_profile" "$HOME/.bash_profile"
}

install_git() {
    info "Installing git configurations..."
    create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
    create_symlink "$DOTFILES_DIR/git/ignore" "$HOME/.config/git/ignore"

    # Create local gitconfig if it doesn't exist
    if [[ ! -f "$HOME/.gitconfig.local" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            cp "$DOTFILES_DIR/git/.gitconfig.local.example" "$HOME/.gitconfig.local"
            warn "Created ~/.gitconfig.local - please edit with your name and email"
        else
            info "[DRY RUN] Would create ~/.gitconfig.local from example"
        fi
    fi
}

install_config() {
    info "Installing tool configurations..."
    create_symlink "$DOTFILES_DIR/config/.ripgreprc" "$HOME/.ripgreprc"
    create_symlink "$DOTFILES_DIR/config/gh" "$HOME/.config/gh"
    create_symlink "$DOTFILES_DIR/config/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
}

install_ssh() {
    info "Installing SSH configuration..."
    create_symlink "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
}

install_agents() {
    warn "The --agents flag is deprecated. Use --claude instead."
    install_claude
}

install_claude() {
    info "Installing Claude Code configuration..."

    # Install global AGENTS.md as CLAUDE.md
    create_symlink "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"

    # Install prompts as commands
    if [[ -d "$DOTFILES_DIR/agents/prompts" ]]; then
        for prompt in "$DOTFILES_DIR/agents/prompts"/*.md; do
            if [[ -f "$prompt" ]] && [[ "$(basename "$prompt")" != ".gitkeep" ]]; then
                create_symlink "$prompt" "$HOME/.claude/commands/$(basename "$prompt")"
            fi
        done
    fi

    # Install subagents
    if [[ -d "$DOTFILES_DIR/agents/subagents" ]]; then
        for subagent in "$DOTFILES_DIR/agents/subagents"/*.md; do
            if [[ -f "$subagent" ]]; then
                create_symlink "$subagent" "$HOME/.claude/agents/$(basename "$subagent")"
            fi
        done
    fi

    # Install skills
    if [[ -d "$DOTFILES_DIR/agents/skills" ]]; then
        for skill_dir in "$DOTFILES_DIR/agents/skills"/*; do
            if [[ -d "$skill_dir" ]] && [[ "$(basename "$skill_dir")" != ".gitkeep" ]]; then
                create_symlink "$skill_dir" "$HOME/.claude/skills/$(basename "$skill_dir")"
            fi
        done
    fi
}

install_codex() {
    info "Installing Codex (OpenAI) configuration..."

    # Install global AGENTS.md
    create_symlink "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.codex/AGENTS.md"

    # Install prompts
    if [[ -d "$DOTFILES_DIR/agents/prompts" ]]; then
        for prompt in "$DOTFILES_DIR/agents/prompts"/*.md; do
            if [[ -f "$prompt" ]] && [[ "$(basename "$prompt")" != ".gitkeep" ]]; then
                create_symlink "$prompt" "$HOME/.codex/prompts/$(basename "$prompt")"
            fi
        done
    fi

    # Install skills
    if [[ -d "$DOTFILES_DIR/agents/skills" ]]; then
        for skill_dir in "$DOTFILES_DIR/agents/skills"/*; do
            if [[ -d "$skill_dir" ]] && [[ "$(basename "$skill_dir")" != ".gitkeep" ]]; then
                create_symlink "$skill_dir" "$HOME/.codex/skills/$(basename "$skill_dir")"
            fi
        done
    fi
}

install_cursor() {
    info "Installing Cursor (global) configuration..."

    # Install prompts to global Cursor commands
    if [[ -d "$DOTFILES_DIR/agents/prompts" ]]; then
        for prompt in "$DOTFILES_DIR/agents/prompts"/*.md; do
            if [[ -f "$prompt" ]] && [[ "$(basename "$prompt")" != ".gitkeep" ]]; then
                create_symlink "$prompt" "$HOME/.cursor/commands/$(basename "$prompt")"
            fi
        done
    fi
}

install_cursor_project() {
    info "Installing Cursor (project) configuration..."

    # Install prompts to project-local .cursor/commands
    if [[ -d "$DOTFILES_DIR/agents/prompts" ]]; then
        for prompt in "$DOTFILES_DIR/agents/prompts"/*.md; do
            if [[ -f "$prompt" ]] && [[ "$(basename "$prompt")" != ".gitkeep" ]]; then
                create_symlink "$prompt" ".cursor/commands/$(basename "$prompt")"
            fi
        done
    fi
}

# Parse arguments
if [[ $# -eq 0 ]]; then
    print_usage
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            INSTALL_ALL=true
            shift
            ;;
        --shell)
            INSTALL_SHELL=true
            shift
            ;;
        --git)
            INSTALL_GIT=true
            shift
            ;;
        --config)
            INSTALL_CONFIG=true
            shift
            ;;
        --ssh)
            INSTALL_SSH=true
            shift
            ;;
        --agents)
            INSTALL_AGENTS=true
            shift
            ;;
        --claude)
            INSTALL_CLAUDE=true
            shift
            ;;
        --codex|--openai)
            INSTALL_CODEX=true
            shift
            ;;
        --cursor)
            INSTALL_CURSOR=true
            shift
            ;;
        --cursor-project)
            INSTALL_CURSOR_PROJECT=true
            shift
            ;;
        --no-backup)
            BACKUP=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Main installation
info "Starting dotfiles installation..."
if [[ "$DRY_RUN" == true ]]; then
    warn "Running in DRY RUN mode - no changes will be made"
fi

if [[ "$INSTALL_ALL" == true ]]; then
    install_shell
    install_git
    install_config
    install_ssh
    install_claude
else
    [[ "$INSTALL_SHELL" == true ]] && install_shell
    [[ "$INSTALL_GIT" == true ]] && install_git
    [[ "$INSTALL_CONFIG" == true ]] && install_config
    [[ "$INSTALL_SSH" == true ]] && install_ssh
    [[ "$INSTALL_AGENTS" == true ]] && install_agents
    [[ "$INSTALL_CLAUDE" == true ]] && install_claude
    [[ "$INSTALL_CODEX" == true ]] && install_codex
    [[ "$INSTALL_CURSOR" == true ]] && install_cursor
    [[ "$INSTALL_CURSOR_PROJECT" == true ]] && install_cursor_project
fi

if [[ "$DRY_RUN" == false ]]; then
    info "Installation complete!"
    if [[ "$BACKUP" == true ]] && [[ -d "$BACKUP_DIR" ]]; then
        info "Backups saved to: $BACKUP_DIR"
    fi
    warn "Don't forget to edit ~/.gitconfig.local with your name and email!"
else
    info "Dry run complete - no changes were made"
fi
