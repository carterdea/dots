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
- `--claude` - Install skills to Claude Code (~/.claude)
- `--codex` / `--openai` - Install skills to Codex (~/.agents)
- `--cursor` - Install skills to Cursor global (~/.cursor)
- `--cursor-project` - Install skills to Cursor project (.cursor)
- `--pi` - Install skills to pi coding agent (~/.pi/agent)
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
    ├── subagents/          # Subagent definitions (5 agents)
    └── skills/             # Skills (51 skills)
```

## AI Assistant Configuration

Your dotfiles include skills that work across Claude Code, Codex, OpenCode, Cursor, and pi.

### Available Skills

**Development Workflow:**
- `/design-doc` - Technical design documents
- `/execute-plan` - Work through a plan file task-by-task
- `/qa` - Browser-based QA against a plan file
- `/handoff` - Continuation prompt for the next session
- `/de-slop` - Remove AI artifacts before PRs
- `/make-tests` - Generate tests for current changes
- `/work-forever` - Highly autonomous long-running task mode
- `/iterate-forever` - Visual-reference-to-app loop with screenshot comparison
- `/dogfood` - Exploratory test web app, structured bug report
- `/qa-gstack` - QA test + fix loop with health scores
- `/qa-gstack-only` - Report-only QA, no code changes
- `/merge-conflicts` - Rebase onto main, resolve conflicts, force-push

**GitHub Workflow:**
- `/gh-ship` - Commit, push, PR in one step
- `/gh-commit` - Conventional commit messages
- `/gh-review-pr` - Thorough PR review
- `/gh-address-pr-comments` - Resolve PR review comments
- `/gh-fix-ci` - Fix first failing CI check
- `/clean-gone` - Remove local branches gone from remote
- `/clean-worktrees` - Audit and clean agent worktrees safely

**Code Quality and Review:**
- `/pre-pr` - Pre-PR validation pipeline (security, types, tests, breaking changes)
- `/rams` - Accessibility and visual design review
- `/code-review-prompt` - Generate review prompt for another Claude session
- `/garry-tan-code-review` - Interactive opinionated code review with sign-off
- `/codex-review` - Second opinion via OpenAI Codex CLI
- `/claude-review` - Second opinion via Claude Code CLI
- `/code-simplifier` - Simplify recently modified code
- `/baseline` - Install quality baseline (linter, hooks, dead-code scan)
- `/react-doctor` - Catch React issues after changes
- `/vercel-react-best-practices` - React/Next.js performance patterns
- `/audit-ai-code` - Triage AI-shaped backend code (duplicate helpers, broad excepts, hallucinated APIs)
- `/audit-ai-frontend` - Triage AI-looking UI (generic aesthetics, weak copy, a11y gaps)
- `/audit-ai-writing` - AI-writing residue checks and citation triage
- `/improve-codebase-architecture` - Find deepening opportunities toward deep modules

**Planning and Thinking:**
- `/grill-me` - Stress-test plan via relentless interview
- `/domain-model` - Grilling session that maintains CONTEXT.md (glossary) and docs/adr/ inline
- `/zoom-out` - Higher-level perspective on a section of code
- `/office-hours` - YC-style forcing questions / brainstorm mode
- `/subagent-orchestrator` - Coordinate sub-agents on long-horizon tasks
- `/pair-programming` - Senior engineer pairing with pushback and scope discipline
- `/prove-it-bug-fix` - Failing reproduction test before fix

**Frontend and Design:**
- `/emil-design-engineering` - Polished, accessible web interface principles
- `/web-animation-design` - Animation patterns and performance
- `/shopify-liquid-patterns` - Liquid code patterns

**Shopify:**
- `/shopify-dev-theme` - Dev theme from current branch
- `/shopify-theme-pull` - Pull merchant content from live theme

**Writing:**
- `/humanize-ai-text` - Rewrite AI text to sound natural / pass detectors
- `/smart-brevity` - Smart Brevity rewriting

**Browser Automation:**
- `/agent-browser` - Standalone browser CLI for navigation, forms, scraping, screenshots

**Meta:**
- `/new-skill` - Create skill from current conversation
- `/skill-creator` - Create, edit, evaluate, benchmark skills
- `/self-improve` - Codex session-driven self-improvement
- `/clean-coder` - Invoked when user swears or is upset

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

# Install to pi coding agent
./install.sh --pi

# Install to OpenCode
./install.sh --opencode

# Install to all (Claude, Cursor, Codex, OpenCode, pi)
./install.sh --all
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
