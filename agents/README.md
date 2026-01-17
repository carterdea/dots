# Agents Configuration

Claude Code configuration with shared prompts and global rules.

## Structure

```
agents/
├── AGENTS.md              # Global Claude Code instructions
├── prompts/               # Slash commands for ~/.claude/commands/
└── skills/                # Future: custom skills
```

## Installation

Run from the repo root (`dots/`):

```bash
./install.sh --agents
```

### What `--agents` installs

- `~/.claude/CLAUDE.md` (copied from `agents/AGENTS.md`)
- `~/.claude/commands/*.md` (copied from `agents/prompts/`)

## Usage

### Global Instructions

Edit `agents/AGENTS.md` to customize Claude's global behavior across all projects.

### Slash Commands

Create `.md` files in `agents/prompts/` to add custom slash commands.

Example: `agents/prompts/gh-commit.md` becomes available as `/gh-commit`

## Common Install Recipes

Install everything:
```bash
./install.sh --all
```

Install only agent config:
```bash
./install.sh --agents
```

Reinstall after updating prompts:
```bash
./install.sh --agents
```
