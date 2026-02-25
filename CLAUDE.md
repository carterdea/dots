# CLAUDE.md

Personal dotfiles and shared agent prompts/skills for macOS.

## Structure

- `install.sh` — symlinks dotfiles and agent configs; use `--dry-run` to preview
- `bootstrap.sh` — fresh macOS setup (Xcode CLI tools, Homebrew, oh-my-zsh, tools)
- `shell/` — zsh/bash configs
- `git/` — gitconfig with local override pattern (`~/.gitconfig.local`)
- `config/` — ripgrep, gh, ghostty
- `ssh/` — SSH config
- `agents/` — Claude Code global config (prompts, skills, subagents)
  - `AGENTS.md` — installed to `~/.claude/CLAUDE.md` via symlink
  - `prompts/` — slash commands (installed to `~/.claude/commands/`)
  - `skills/` — on-demand skill definitions
  - `subagents/` — subagent definitions

## Install

```bash
./install.sh --all          # everything
./install.sh --claude       # just Claude Code config
./install.sh --all --dry-run # preview
```

## Testing changes

- Use `--dry-run` before real installs
- After install, verify symlinks: `ls -la ~/.claude/CLAUDE.md`
- Shell changes need `source ~/.zshrc` or a new terminal
