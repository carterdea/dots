# Agents Configuration

Claude Code configuration with shared prompts, subagents, and skills.

## Structure

```
agents/
├── AGENTS.md              # Global Claude Code instructions
├── prompts/               # Slash commands for ~/.claude/commands/
│   ├── de-slop.md                 # Remove AI artifacts before PRs
│   ├── design-doc.md              # Create technical design documents
│   ├── execute-plan.md            # Work through a plan file task-by-task
│   ├── gh-address-pr-comments.md  # Resolve PR review comments
│   ├── gh-commit.md               # Create well-formatted commits
│   ├── gh-fix-ci.md               # Debug and fix failing CI checks
│   ├── gh-review-pr.md            # Review PRs thoroughly
│   ├── gh-ship.md                 # Commit, push, and create PR in one step
│   ├── handoff.md                 # Generate a continuation prompt for the next session
│   ├── make-tests.md              # Generate tests for changes
│   ├── new-cmd.md                 # Create new commands from conversations
│   ├── new-skill.md               # Create new skills from workflows
│   ├── pre-pr.md                  # Complete pre-PR validation pipeline
│   ├── python-qa.md               # Python QA pipeline
│   ├── qa.md                      # Browser-based QA against a plan file
│   ├── rams.md                    # Accessibility and visual design review
│   ├── shopify-dev-theme.md       # Create dev theme from git branch
│   ├── shopify-theme-pull.md      # Pull merchant content from live theme
│   └── work-forever.md            # Autonomous long-running task mode
├── subagents/             # Subagent definitions for ~/.claude/agents/
│   ├── pr-description-gen.md      # Auto-generate PR descriptions
│   ├── security-scanner.md        # Scan for security vulnerabilities
│   ├── breaking-change-detector.md # Detect API/schema breaking changes
│   ├── python-type-fixer.md       # Modernize Python type annotations
│   └── python-code-simplifier.md  # Python refactoring suggestions
└── skills/                # Claude Code skills for ~/.claude/skills/
    ├── code-review-prompt/        # Generate code review prompts
    ├── emil-design-engineering/   # Design engineering principles
    ├── garry-tan-code-review/     # Interactive opinionated code review
    ├── humanize-ai-text/          # Detect and transform AI-generated text patterns
    ├── pair-programming/          # Senior engineer pairing mode
    ├── prove-it-bug-fix/          # Bug reproduction workflow
    ├── shopify-liquid-patterns/   # Shopify Liquid patterns
    └── web-animation-design/      # Animation patterns
```

## Installation

Run from the repo root (`dots/`):

```bash
./install.sh --claude
```

### What `--claude` installs

- `~/.claude/CLAUDE.md` (symlink to `agents/AGENTS.md`)
- `~/.claude/commands/*.md` (symlinks to `agents/prompts/*.md`)
- `~/.claude/agents/*.md` (symlinks to `agents/subagents/*.md`)
- `~/.claude/skills/*` (symlinks to `agents/skills/*`)

## Available Commands

### Development Workflow

#### `/design-doc`
Create a technical design document for a feature or system. Produces a plan file with implementation tasks, open questions, and architectural decisions.

#### `/execute-plan`
Work through a plan file task-by-task, checking off items as they complete.

Options:
- `--commit-per-task` - Commit after each individual task (default: per-phase)
- `--commit-end-only` - Commit only when all tasks are done
- `--dry-run` - Preview tasks, open questions, and detected tooling without executing

#### `/qa`
Verify completed work in the browser using `- [ ] QA:` items from a plan file. Uses Playwright for browser automation.

```bash
/qa docs/my_feature_PLAN.md --url http://localhost:3000
```

#### `/handoff`
Generate a continuation prompt so the next session can pick up exactly where this one left off. Detects pipeline position, git state, and remaining tasks.

#### `/de-slop`
Remove AI artifacts before opening a PR — scratch markdown, filler documentation, over-engineered patterns, and other signs of AI-generated code that shouldn't ship.

#### `/make-tests`
Generate tests for recent changes. Covers happy path and edge cases.

#### `/design-doc`
Create a technical design document for a feature or system.

#### `/work-forever`
Autonomous long-running task mode. Keeps working through a task list without stopping for confirmation.

---

### GitHub Workflow

#### `/gh-ship`
Commit, push, and open a PR in one step.

#### `/gh-commit`
Create a well-formatted, imperative commit message from staged changes.

#### `/gh-review-pr`
Thorough PR review covering architecture, code quality, tests, and performance.

#### `/gh-address-pr-comments`
Read all open review comments on the current PR and resolve them.

#### `/gh-fix-ci`
Debug and fix failing CI checks.

---

### Code Quality

#### `/pre-pr`
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

#### `/python-qa`
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

#### `/rams`
Accessibility and visual design review against WCAG guidelines.

---

### Shopify

#### `/shopify-dev-theme`
Create a dev theme from the current git branch.

#### `/shopify-theme-pull`
Pull merchant-edited content (`config/settings_data.json` and `templates/`) from a live Shopify theme. Shows a diff summary and optionally commits the changes.

---

### Meta

#### `/new-cmd`
Create a new slash command from the current conversation.

#### `/new-skill`
Create a new skill from a workflow demonstrated in the current conversation.

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

### `pair-programming`
Senior engineer pairing mode with assumption surfacing, pushback, scope discipline, and simplicity enforcement. Invoke at the start of focused coding sessions.

### `prove-it-bug-fix`
Reproduce bugs with a failing test before attempting fixes. Ensures bugs are properly captured and fixes are verified.

### `code-review-prompt`
Generates comprehensive code review prompts that can be copied into another Claude session. Automatically detects your tech stack and tailors the review checklist.

### `emil-design-engineering`
Design engineering principles for building polished, accessible web interfaces. Covers animations, UI polish, forms, touch/accessibility, and performance.

### `web-animation-design`
Animation patterns and implementation guidance. Includes easing functions, timing, and practical tips for web animations.

### `shopify-liquid-patterns`
Common Liquid code patterns for Shopify theme development. Useful when writing templates, handling translations, or product displays.

### `garry-tan-code-review`
Interactive, opinionated code review. Works through architecture, code quality, tests, and performance one area at a time — pausing for feedback after each. For each issue, presents 2–3 lettered options with effort/risk/impact analysis and a clear recommendation before making any changes.

### `humanize-ai-text`
Detect and transform AI-generated writing patterns. Checks 16 pattern categories (citation bugs, chatbot artifacts, AI vocabulary, filler phrases, etc.) and auto-fixes the most detectable signals. Includes three Python scripts: `detect.py`, `transform.py`, and `compare.py`.

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

Install only Claude Code config:
```bash
./install.sh --claude
```

Reinstall after updating prompts:
```bash
./install.sh --claude
```
