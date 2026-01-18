#!/usr/bin/env bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Bootstrap script - run this on a fresh macOS install
info "Starting dotfiles bootstrap..."

# Check for Command Line Tools
if ! xcode-select -p &> /dev/null; then
    warn "Xcode Command Line Tools not found. Installing..."
    xcode-select --install
    warn "Please complete the installation and re-run this script."
    exit 1
fi

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    info "Homebrew already installed"
fi

# Install oh-my-zsh if not present
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    info "oh-my-zsh already installed"
fi

# Clone dotfiles if not present
DOTFILES_DIR="$HOME/dots"
if [[ ! -d "$DOTFILES_DIR" ]]; then
    info "Cloning dotfiles repository..."
    git clone https://github.com/carterdea/dots.git "$DOTFILES_DIR"
else
    info "Dotfiles already cloned"
fi

# Install essential tools
info "Installing essential development tools..."
brew install \
    bat \
    fd \
    ripgrep \
    zoxide \
    git \
    gh \
    tig

# Install Bun
if ! command -v bun &> /dev/null; then
    info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
else
    info "Bun already installed"
fi

# Install Claude Code
if ! command -v claude &> /dev/null; then
    info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
else
    info "Claude Code already installed"
fi

# Run the dotfiles installer
info "Running dotfiles installer..."
cd "$DOTFILES_DIR"
./install.sh --all

info "Bootstrap complete!"
warn "Please restart your terminal or run: source ~/.zshrc"
