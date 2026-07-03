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
- `--pi` - Install skills and packages to pi coding agent (~/.pi/agent)
- `--pi-packages` - Install pi packages listed in `agents/pi-packages.txt`
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

## Testing

Validate the install scripts and config sources before committing:

```bash
./tests/run_tests.sh
```

This runs `shellcheck` on `install.sh`/`bootstrap.sh` and the bats suites
(`install.bats`, `source_files.bats`), which assert the installer is executable
and every file it symlinks actually exists. Pair with `./install.sh --all --dry-run`
to preview symlink changes without touching your home directory.

## Structure

```
dots/
├── bootstrap.sh            # Fresh macOS setup script
├── install.sh              # Installation script
├── Brewfile                # Homebrew package list
├── CLAUDE.md               # Repo-specific agent instructions
├── README.md               # This file
├── tests/                  # bats + shellcheck suite (run_tests.sh)
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
└── agents/                 # Shared agent config (Claude, Codex, OpenCode, Cursor, pi)
    ├── AGENTS.md           # Global instructions
    ├── pi-packages.txt     # pi extension package sources
    ├── subagents/          # Subagent definitions (14 agents)
    └── skills/             # Skills (78 skills)
```

## AI Assistant Configuration

Your dotfiles include skills that work across Claude Code, Codex, OpenCode, Cursor, and pi.

Pi package sources live in `agents/pi-packages.txt`. `./install.sh --pi` and `./install.sh --pi-packages` install those packages through `pi install`, so pi can keep extension package sources in `~/.pi/agent/settings.json` without symlinking local extension code.

Some shared skills include a `package.json` for local validation helpers. Any agent install target (`--claude`, `--codex`, `--cursor`, `--opencode`, `--pi`, or `--all`) runs `bun install` in those skill directories so their scripts work through the symlinks.

### Available Skills

**Development Workflow:**
- `/app-store-preflight-compliance` - Pre-submission App Store compliance scanner workflow
- `/design-doc` - Technical design documents
- `/execute-plan` - Work through a plan file task-by-task
- `/qa` - Browser-based QA against a plan file
- `/handoff` - Continuation prompt for the next session
- `/de-slop` - Remove AI artifacts and clean AI-shaped code before PRs
- `/make-tests` - Generate tests for current changes
- `/iterate-forever` - Visual-reference-to-app loop with screenshot comparison
- `/dogfood` - Exploratory test web app, structured bug report
- `/merge-conflicts` - Rebase onto main, resolve conflicts, force-push
- `/simple-html-artifact` - Build or refine single-file HTML artifacts

**GitHub Workflow:**
- `/gh-ship` - Commit, push, PR in one step
- `/gh-commit` - Conventional commit messages
- `/gh-review-pr` - Thorough PR review
- `/gh-address-pr-comments` - Watch PR comments and fix valid review feedback
- `/gh-fix-ci` - Fix first failing CI check
- `/clean-worktrees` - Audit and clean agent worktrees and gone branches safely
- `/trello-delivery` - Ship a Trello ticket end to end as a reviewable PR (non-Shopify web apps). Requires the `trello-cli` binary from [Scale-Flow/trello-cli](https://github.com/Scale-Flow/trello-cli)

**Code Quality and Review:**
- `/pre-pr` - Project-appropriate validation, release-risk review, and PR summary
- `/rams` - Accessibility and visual design review
- `/codex-review` - Second opinion via OpenAI Codex CLI
- `/claude-review` - Second opinion via Claude Code CLI
- `/code-simplifier` - Simplify recently modified code
- `/database-schema-designer` - Design robust SQL and NoSQL schemas
- `/baseline` - Install quality baseline (linter, hooks, dead-code scan)
- `/quality-python` - Python structure, typing, error handling, IO, and tests
- `/quality-react` - React structure, state ownership, effects, accessibility, and tests
- `/quality-ruby` - Ruby/Rails structure, ActiveRecord, errors, and RSpec quality
- `/quality-typescript` - Stronger TypeScript domain types, strictness, and test boundaries
- `/react-doctor` - Catch React issues after changes
- `/react-router` - React Router patterns and mode-specific guidance
- `/vercel-react-best-practices` - React/Next.js performance patterns
- `/nestjs-best-practices` - NestJS architecture and API patterns
- `/security-audit` - Security review for vulnerabilities and secret exposure
- `/audit-ai-frontend` - Triage AI-looking UI (generic aesthetics, weak copy, a11y gaps)
- `/improve` - Senior codebase survey and improvement plan
- `/improve-codebase-architecture` - Find deepening opportunities toward deep modules
- `/coobeyon-refactor` - Refactor orchestration-heavy code toward smaller modules
- `/thermo-nuclear-code-quality-review` - Extremely strict maintainability review

**Planning and Thinking:**
- `/grill-me` - Stress-test plan via relentless interview
- `/grilling` - Relentless one-question-at-a-time planning interview
- `/loop-me` - Specify recurring workflows through grilling
- `/domain-model` - Grilling session that maintains CONTEXT.md (glossary) and docs/adr/ inline
- `/zoom-out` - Higher-level perspective on a section of code
- `/subagent-orchestrator` - Coordinate sub-agents on long-horizon tasks
- `/prove-it-bug-fix` - Failing reproduction test before fix
- `/ultragoal` - Design, critique, set, or update explicit long-horizon goals

**Frontend and Design:**
- `/emil-design-engineering` - Polished, accessible web interface principles
- `/interface-details` - Crafted UI micro-interactions and details
- `/no-ui-flash` - Prevent wrong-state flashes in SPA/SSR auth and state gates
- `/web-animation-design` - Animation patterns and performance
- `/shopify-liquid-patterns` - Liquid code patterns
- `/vertical-feature-architect` - Add net-new product workflows across a stack

**Shopify:**
- `/shopify-app-store-review` - Shopify App Store review requirements
- `/shopify-baseline` - Shopify theme/app quality baseline
- `/shopify-dev-theme` - Dev theme from current branch
- `/shopify-payments-apps` - Shopify payments app APIs and validation
- `/shopify-polaris-admin-extensions` - Polaris Admin UI extension code and validation
- `/shopify-polaris-app-home` - Polaris app home code and validation
- `/shopify-storefront-graphql` - Storefront GraphQL queries, mutations, and validation
- `/shopify-theme-pull` - Pull merchant content from live theme
- `/shopify-trello-delivery` - Ship Shopify Trello tickets through PR, preview theme, screenshots, and Trello handoff. Requires the `trello-cli` binary from [Scale-Flow/trello-cli](https://github.com/Scale-Flow/trello-cli)
- `/shopify-trello-qa` - Verify finished Shopify Trello ticket work
- `/shopify-use-shopify-cli` - Shopify CLI operational workflows

**Writing:**
- `/humanize-ai-text` - Humanize AI-shaped writing, audit LLM residue, and triage citations
- `/smart-brevity` - Smart Brevity rewriting
- `/write-better-error-messages` - Product error message review and rewrite
- `/writing-great-skills` - Reference for writing and editing skills

**Browser Automation:**
- `/agent-browser` - Standalone browser CLI for navigation, forms, scraping, screenshots

**External Tools:**
- `/asana-cli` - Manage Asana tasks and projects through the `asana` CLI
- `/trello-cli` - Drive Trello (boards, lists, cards, comments, checklists, labels) through the `trello-cli`. Requires the binary from [Scale-Flow/trello-cli](https://github.com/Scale-Flow/trello-cli)

**Meta:**
- `/skill-creator` - Create, edit, evaluate, benchmark skills
- `/self-improve` - Codex session-driven self-improvement
- `/clean-coder` - Invoked when user swears or is upset
- `/teach` - Teach a skill or concept with workspace-local lessons
- `/wizard` - Generate interactive bash wizards

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

# Install only pi packages
./install.sh --pi-packages

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
