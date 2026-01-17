# Agents Configuration

Claude Code configuration with shared prompts, subagents, and skills.

## Structure

```
agents/
├── AGENTS.md              # Global Claude Code instructions
├── prompts/               # Slash commands for ~/.claude/commands/
│   ├── pre-pr.md          # Complete pre-PR validation pipeline
│   └── python-qa.md       # Python QA pipeline
├── subagents/             # Subagent definitions for ~/.claude/agents/
│   ├── pr-description-gen.md      # Auto-generate PR descriptions
│   ├── security-scanner.md        # Scan for security vulnerabilities
│   ├── breaking-change-detector.md # Detect API/schema breaking changes
│   ├── python-type-fixer.md       # Modernize Python type annotations
│   └── python-code-simplifier.md  # Python refactoring suggestions
└── skills/                # Claude Code skills for ~/.claude/skills/
    └── code-review-prompt/        # Generate code review prompts
```

## Installation

Run from the repo root (`dots/`):

```bash
./install.sh --agents
```

### What `--agents` installs

- `~/.claude/CLAUDE.md` (symlink to `agents/AGENTS.md`)
- `~/.claude/commands/*.md` (symlinks to `agents/prompts/*.md`)
- `~/.claude/agents/*.md` (symlinks to `agents/subagents/*.md`)
- `~/.claude/skills/*` (symlinks to `agents/skills/*`)

## Available Commands

### `/pre-pr`
Complete validation pipeline before creating a pull request:
- Security scan (secrets, injection risks)
- Compliance check (project rules)
- Architecture validation
- Test coverage gate
- Breaking change detection
- Performance analysis
- Type modernization
- Code simplification
- Run tests & linters
- Generate PR description

Options:
- `--quick` - Fast mode, critical checks only
- `--no-tests` - Skip test execution
- `--python-only` - Only check Python code
- `--typescript-only` - Only check TypeScript code

### `/python-qa`
Python-specific QA pipeline:
- Security scan
- Compliance check (PEP rules, type hints)
- Type modernization (PEP 585/604)
- Architecture validation
- Performance analysis
- Code simplification
- Verification (ruff + basedpyright)

Options:
- `--quick` - Run only critical checks

## Available Subagents

### `pr-description-gen`
Automatically generates comprehensive PR descriptions with:
- Summary of changes
- Test plan
- Breaking changes section
- Changelog entries

### `security-scanner`
Scans code for security vulnerabilities:
- Hardcoded secrets (API keys, passwords)
- SQL/Command injection risks
- SSRF vulnerabilities
- OWASP Top 10 issues

### `breaking-change-detector`
Detects breaking changes in:
- API endpoints (added/removed/modified)
- Response/request schemas
- Database migrations
- Configuration changes

### `python-type-fixer`
Modernizes Python type annotations:
- `Optional[X]` → `X | None`
- `List[X]` → `list[X]`
- `Dict[K, V]` → `dict[K, V]`
- `Union[X, Y]` → `X | Y`

### `python-code-simplifier`
Suggests Python refactoring:
- Reduce function complexity
- Remove duplicate code
- Simplify error handling
- Improve readability

## Available Skills

### `code-review-prompt`
Generates comprehensive code review prompts that can be copied into another Claude session. Automatically detects your tech stack and tailors the review checklist.

Usage: Run as a skill to generate a prompt for your current branch.

## Adding Custom Content

### New Slash Command
```bash
# Create a new command file
echo "---
description: My custom command
---

# My Command

Your command instructions here..." > agents/prompts/my-command.md

# Reinstall
./install.sh --agents
```

The command will be available as `/my-command`.

### New Subagent
```bash
# Create subagent definition
echo "---
name: my-agent
description: What this agent does
tools: Read, Grep, Glob, Bash
model: sonnet
---

Your agent instructions..." > agents/subagents/my-agent.md

# Reinstall
./install.sh --agents
```

### New Skill
```bash
# Create skill directory and definition
mkdir -p agents/skills/my-skill
echo "---
name: my-skill
description: What this skill does
allowed-tools: Bash
user-invocable: true
---

Your skill instructions..." > agents/skills/my-skill/SKILL.md

# Reinstall
./install.sh --agents
```

## Usage Examples

### Before Creating a PR
```bash
# Run complete validation
/pre-pr

# Or quick mode
/pre-pr --quick
```

### Python Code Review
```bash
# Full pipeline
/python-qa

# Quick check
/python-qa --quick
```

### Generate Code Review
Run the `code-review-prompt` skill to generate a review prompt, then paste it into a fresh Claude session for an unbiased review.

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
