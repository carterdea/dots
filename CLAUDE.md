# CLAUDE.md

Personal dotfiles and shared agent skills for macOS.

## Structure

- `install.sh` — symlinks dotfiles and agent configs; use `--dry-run` to preview
- `bootstrap.sh` — fresh macOS setup (Xcode CLI tools, Homebrew, oh-my-zsh, tools)
- `shell/` — zsh/bash configs
- `git/` — gitconfig with local override pattern (`~/.gitconfig.local`)
- `config/` — ripgrep, gh, ghostty
- `ssh/` — SSH config
- `agents/` — shared agent instructions and skills
  - `AGENTS.md` — installed to Claude, OpenCode, and other agent configs via symlink
  - `skills/` — shared user-invocable skills
  - `subagents/` — subagent definitions
- `.opencode/` — OpenCode config examples

## Install

```bash
./install.sh --all          # everything
./install.sh --claude       # just Claude Code config
./install.sh --opencode     # just OpenCode config
./install.sh --all --dry-run # preview
```

## Testing changes

- Use `--dry-run` before real installs
- After install, verify symlinks: `ls -la ~/.claude/CLAUDE.md`
- After OpenCode install, verify: `ls -la ~/.config/opencode/AGENTS.md`
- Shell changes need `source ~/.zshrc` or a new terminal
