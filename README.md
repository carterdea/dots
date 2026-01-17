# Dotfiles

Personal dotfiles for macOS development environment.

## What's Included

- **Shell**: Zsh and Bash configurations with oh-my-zsh
- **Git**: Git configuration with Kaleidoscope integration and useful aliases
- **SSH**: macOS keychain integration
- **Tools**: Ripgrep, GitHub CLI
- **AI**: Claude Code global configuration

## Prerequisites

- macOS (Darwin)
- [Homebrew](https://brew.sh/)
- [oh-my-zsh](https://ohmyz.sh/)
- Git

### Optional Dependencies

- [Cursor](https://cursor.sh/) - Code editor
- [Sublime Text](https://www.sublimetext.com/) - Text editor
- [Kaleidoscope](https://kaleidoscope.app/) - Diff/merge tool
- [ripgrep](https://github.com/BurntSushi/ripgrep) - `brew install ripgrep`
- [GitHub CLI](https://cli.github.com/) - `brew install gh`

## Installation

Clone this repository:

```bash
git clone https://github.com/YOUR_USERNAME/dots.git ~/dots
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

- `--all` - Install all configurations
- `--shell` - Install shell configs (.zshrc, .bashrc, etc.)
- `--git` - Install git configurations
- `--config` - Install tool configs (ripgrep, gh)
- `--ssh` - Install SSH config
- `--claude` - Install Claude AI config
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

### Shell Reload

```bash
# Reload zsh
source ~/.zshrc

# Or open a new terminal
```

## Structure

```
dots/
├── install.sh              # Installation script
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
│   └── gh/
│       └── config.yml
├── ssh/                    # SSH configuration
│   └── config
└── claude/                 # Claude AI configuration
    └── CLAUDE.md
```

## Features

### Shell

- Clean, organized zsh configuration
- oh-my-zsh with useful plugins (git, docker, z, colorize)
- History configuration (10k lines, deduplication, sharing)
- NVM, RVM, Bun, Rust support
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

Inspired by [jxnl/dots](https://github.com/jxnl/dots)
