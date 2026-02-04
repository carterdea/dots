# Dotfiles

Personal dotfiles for macOS development environment.

## What's Included

- **Shell**: Zsh and Bash configurations with oh-my-zsh
- **Git**: Git configuration with Kaleidoscope integration and useful aliases
- **SSH**: macOS keychain integration
- **Terminal**: Ghostty terminal emulator configuration
- **Tools**: Ripgrep, GitHub CLI
- **AI**: Claude Code global configuration

## Prerequisites

For a fresh macOS machine, you only need:

- **macOS** (any recent version)
- **Internet connection**
- **Terminal** access

The bootstrap script will automatically install everything else, including:
- Xcode Command Line Tools
- Homebrew
- oh-my-zsh
- Git
- Essential development tools (bat, fd, ripgrep, zoxide, gh, tig)
- Bun (JavaScript runtime)
- Claude Code (AI coding assistant)

### Optional Applications

These are referenced in configs but not required:

- [Cursor](https://cursor.sh/) - Code editor
- [Sublime Text](https://www.sublimetext.com/) - Text editor
- [Kaleidoscope](https://kaleidoscope.app/) - Git diff/merge tool
- [Ghostty](https://ghostty.org/) - Terminal emulator

## Quick Start (Fresh macOS Install)

For a completely fresh macOS machine:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/carterdea/dots/main/bootstrap.sh)
```

This will:
1. Install Xcode Command Line Tools
2. Install Homebrew
3. Install oh-my-zsh
4. Clone this repository
5. Install essential tools (bat, fd, ripgrep, zoxide, gh, tig)
6. Install Bun
7. Install Claude Code
8. Run the dotfiles installer

## Manual Installation

Clone this repository:

```bash
git clone https://github.com/carterdea/dots.git ~/dots
cd ~/dots
```

### Install Everything

```bash
./install.sh --all
```

### Install Specific Components

```bash
# Shell configurations only
./install.sh --shell

# Git and shell
./install.sh --git --shell

# Preview without making changes
./install.sh --all --dry-run
```

### Available Flags

- `--all` - Install all configurations (includes Claude Code)
- `--shell` - Install shell configs (.zshrc, .bashrc, etc.)
- `--git` - Install git configurations
- `--config` - Install tool configs (ripgrep, gh, ghostty)
- `--ssh` - Install SSH config
- `--claude` - Install prompts/skills to Claude Code (~/.claude)
- `--codex` / `--openai` - Install prompts/skills to Codex (~/.codex)
- `--cursor` - Install prompts to Cursor global (~/.cursor)
- `--cursor-project` - Install prompts to Cursor project (.cursor)
- `--no-backup` - Skip backing up existing files
- `--dry-run` - Preview changes without applying them

## Post-Installation

### Git Configuration

Edit `~/.gitconfig.local` with your personal information:

```bash
cursor ~/.gitconfig.local
```

```ini
[user]
    name = Your Name
    email = your.email@example.com
```

### AI Assistant Configuration

If you installed Codex, edit `~/.codex/config.toml` with your API keys:

```bash
cursor ~/.codex/config.toml
```

Replace the placeholder values:
- `ghp_YOUR_GITHUB_PAT_HERE` → Your GitHub PAT from https://github.com/settings/tokens
- `ctx7sk-YOUR_CONTEXT7_KEY_HERE` → Your Context7 key from https://context7.com

### Shell Reload

```bash
# Reload zsh
source ~/.zshrc

# Or open a new terminal
```

## Brewfile

Install all packages from the Brewfile:

```bash
brew bundle install --file=~/dots/Brewfile
```

Generate a new Brewfile from your current setup:

```bash
brew bundle dump --file=~/dots/Brewfile --force
```

## Structure

```
dots/
├── bootstrap.sh            # Fresh macOS setup script
├── install.sh              # Installation script
├── Brewfile                # Homebrew package list
├── README.md               # This file
├── shell/                  # Shell configurations
│   ├── .zshrc
│   ├── .zprofile
│   ├── .bashrc
│   └── .bash_profile
├── git/                    # Git configurations
│   ├── .gitconfig
│   ├── .gitconfig.local.example
│   └── ignore
├── config/                 # Tool configurations
│   ├── .ripgreprc
│   ├── gh/
│   │   └── config.yml
│   └── ghostty/
│       └── config
├── ssh/                    # SSH configuration
│   └── config
└── agents/                 # Claude Code agents configuration
    ├── AGENTS.md           # Global instructions
    ├── prompts/            # Slash commands
    └── skills/             # Custom skills
        ├── code-review-prompt/
        ├── emil-design-engineering/
        ├── pair-programming/
        ├── prove-it-bug-fix/
        ├── shopify-liquid-patterns/
        └── web-animation-design/
```

## AI Assistant Configuration

Your dotfiles include prompts (slash commands) and skills that work across Claude Code, Codex, and Cursor.

### Available Prompts

**Development Workflow:**
- `/de-slop` - Remove AI artifacts before PRs
- `/make-tests` - Generate tests for your changes
- `/design-doc` - Create technical design documents
- `/work-forever` - Autonomous long-running task mode

**GitHub Workflow:**
- `/gh-ship` - Commit, push, and create PR in one step
- `/gh-commit` - Create well-formatted commits
- `/gh-review-pr` - Review PRs thoroughly
- `/gh-address-pr-comments` - Resolve PR review comments
- `/gh-fix-ci` - Debug and fix failing CI checks

**Code Quality:**
- `/pre-pr` - Pre-PR validation (security, tests, breaking changes)
- `/python-qa` - Run Python QA pipeline
- `/rams` - Accessibility and visual design review

**Shopify:**
- `/shopify-dev-theme` - Create dev theme from git branch

**Meta:**
- `/new-cmd` - Create new commands from conversations
- `/new-skill` - Create new skills from workflows

### Available Skills

Skills are loaded on-demand to provide specialized context and behaviors.

**Coding Workflow:**
- `/pair-programming` - Senior engineer pairing mode with assumption surfacing, pushback, and scope discipline
- `/prove-it-bug-fix` - Reproduce bugs with failing tests before fixing
- `/code-review-prompt` - Generate comprehensive code review prompts

**Frontend Development:**
- `/emil-design-engineering` - Design engineering principles for polished, accessible web interfaces
- `/web-animation-design` - Animation patterns and implementation guidance
- `/shopify-liquid-patterns` - Common Liquid code patterns for Shopify themes

### Installation Options

```bash
# Install to Claude Code only
./install.sh --claude

# Install to Cursor global
./install.sh --cursor

# Install to Cursor project-local
./install.sh --cursor-project

# Install to Codex
./install.sh --codex

# Install to all (Claude, Cursor, Codex)
./install.sh --claude --cursor --codex
```

## Features

### Shell

- Clean, organized zsh configuration
- oh-my-zsh with useful plugins (git, docker, z, colorize)
- History configuration (10k lines, deduplication, sharing)
- asdf version manager, NVM, Bun, Rust support
- Useful aliases

### Git

- Default branch: `main`
- Auto-setup remote on push
- Kaleidoscope for diffs and merges
- Useful aliases (`st`, `co`, `br`, `lg`)
- Better diff output with color-moved

### Global Gitignore

Automatically ignores common files:
- macOS files (`.DS_Store`)
- IDE configs (`.vscode/`, `.idea/`)
- Environment files (`.env*`)
- Build outputs (`dist/`, `__pycache__/`)
- Dependencies (`node_modules/`)

## Uninstallation

The install script creates backups in `~/.dotfiles-backup-TIMESTAMP/`. To restore:

```bash
# Find your backup
ls -la ~ | grep dotfiles-backup

# Restore from backup
cp -r ~/.dotfiles-backup-TIMESTAMP/.zshrc ~/.zshrc
```

## Credits

Inspired by [jxnl/dots](https://github.com/jxnl/dots) & [brendon-codes/dotfiles](https://github.com/brendon-codes/dotfiles)
