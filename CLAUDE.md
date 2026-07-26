# CLAUDE.md

Personal dotfiles and shared agent skills for macOS.

## Structure

- `install.sh` — symlinks dotfiles and agent configs; use `--dry-run` to preview
- `bootstrap.sh` — fresh macOS setup (Xcode CLI tools, Homebrew, oh-my-zsh, tools)
- `shell/` — zsh/bash configs
- `bin/` — scripts symlinked into `~/.local/bin` (ci-lock: machine-wide flock queue serializing heavy checks; lefthook-ci-lock: LEFTHOOK_BIN shim queueing all pre-push hooks through it)
- `git/` — gitconfig with local override pattern (`~/.gitconfig.local`)
- `config/` — ripgrep, gh, ghostty
- `ssh/` — SSH config
- `agents/` — shared agent instructions and skills
  - `AGENTS.md` — installed to Claude, OpenCode, pi, and other agent configs via symlink
  - `skills/` — shared user-invocable skills (Agent Skills standard: `SKILL.md` + frontmatter), compatible with Claude Code, Codex CLI, OpenCode, Cursor, and pi
  - `subagents/` — subagent definitions
- `.opencode/` — OpenCode config examples

## Install

```bash
./install.sh --all          # everything (claude, codex, opencode, cursor, pi)
./install.sh --claude       # just Claude Code config
./install.sh --opencode     # just OpenCode config
./install.sh --pi           # just pi coding agent config
./install.sh --all --dry-run # preview
```

## Testing changes

- Use `--dry-run` before real installs
- After install, verify symlinks: `ls -la ~/.claude/CLAUDE.md`
- After OpenCode install, verify: `ls -la ~/.config/opencode/AGENTS.md`
- Shell changes need `exec zsh` or a new terminal; `source ~/.zshrc` skips `.zshenv`
