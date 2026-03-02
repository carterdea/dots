# Agents Configuration

Claude Code configuration with shared skills, and subagents.

## Structure

```
agents/
├── AGENTS.md              # Global Claude Code instructions
├── subagents/             # Subagent definitions for ~/.claude/agents/
│   ├── pr-description-gen.md      # Auto-generate PR descriptions
│   ├── security-scanner.md        # Scan for security vulnerabilities
│   ├── breaking-change-detector.md # Detect API/schema breaking changes
│   ├── python-type-fixer.md       # Modernize Python type annotations
│   └── python-code-simplifier.md  # Python refactoring suggestions
└── skills/                # Skills for ~/.claude/skills/ and ~/.agents/skills/
    ├── code-review-prompt/        # Generate code review prompts
    ├── de-slop/                   # Remove AI artifacts before PRs
    ├── design-doc/                # Create technical design documents
    ├── emil-design-engineering/   # Design engineering principles
    ├── execute-plan/              # Work through a plan file task-by-task
    ├── garry-tan-code-review/     # Interactive opinionated code review
    ├── gh-address-pr-comments/    # Resolve PR review comments
    ├── gh-commit/                 # Create well-formatted commits
    ├── gh-fix-ci/                 # Debug and fix failing CI checks
    ├── gh-review-pr/              # Review PRs thoroughly
    ├── gh-ship/                   # Commit, push, and create PR in one step
    ├── handoff/                   # Generate continuation prompts
    ├── humanize-ai-text/          # Detect and transform AI-generated text patterns
    ├── make-tests/                # Generate tests for changes
    ├── new-cmd/                   # Create new skills from conversations
    ├── new-skill/                 # Create new skills from workflows
    ├── pair-programming/          # Senior engineer pairing mode
    ├── pre-pr/                    # Complete pre-PR validation pipeline
    ├── prove-it-bug-fix/          # Bug reproduction workflow
    ├── qa/                        # Browser-based QA against a plan file
    ├── rams/                      # Accessibility and visual design review
    ├── shopify-dev-theme/         # Create dev theme from git branch
    ├── shopify-liquid-patterns/   # Shopify Liquid patterns
    ├── shopify-theme-pull/        # Pull merchant content from live theme
    ├── smart-brevity/             # Smart Brevity writing style
    ├── web-animation-design/      # Animation patterns
    └── work-forever/              # Autonomous long-running task mode
```

## Installation

Run from the repo root (`dots/`):

```bash
./install.sh --claude
```

### What `--claude` installs

- `~/.claude/CLAUDE.md` (symlink to `agents/AGENTS.md`)
- `~/.claude/agents/*.md` (symlinks to `agents/subagents/*.md`)
- `~/.claude/skills/*` (symlinks to `agents/skills/*`)

## Available Skills

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
Remove AI artifacts before opening a PR -- scratch markdown, filler documentation, over-engineered patterns, and other signs of AI-generated code that shouldn't ship.

#### `/make-tests`
Generate tests for recent changes. Covers happy path and edge cases.

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

#### `/rams`
Accessibility and visual design review against WCAG guidelines.

---

### Shopify

#### `/shopify-dev-theme`
Create a dev theme from the current git branch.

#### `/shopify-theme-pull`
Pull merchant-edited content (`config/settings_data.json` and `templates/`) from a live Shopify theme. Shows a diff summary and optionally commits the changes.

---

### Coding Workflow

#### `/pair-programming`
Senior engineer pairing mode with assumption surfacing, pushback, scope discipline, and simplicity enforcement.

#### `/prove-it-bug-fix`
Reproduce bugs with failing tests before fixing.

#### `/code-review-prompt`
Generate comprehensive code review prompts for another Claude session.

#### `/garry-tan-code-review`
Interactive, opinionated code review with options A/B/C and explicit sign-off before changes.

---

### Frontend Development

#### `/emil-design-engineering`
Design engineering principles for polished, accessible web interfaces.

#### `/web-animation-design`
Animation patterns and implementation guidance.

#### `/shopify-liquid-patterns`
Common Liquid code patterns for Shopify themes.

---

### Writing

#### `/humanize-ai-text`
Detect and rewrite AI-generated text patterns to sound natural.

#### `/smart-brevity`
Rewrite text using Smart Brevity principles -- shorter, sharper, audience-first communication.

---

### Meta

#### `/new-cmd`
Create a new skill from the current conversation.

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

## Adding Custom Content

### New Skill
```bash
# Create skill directory and definition
mkdir -p agents/skills/my-skill
cat > agents/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: What this skill does
user-invocable: true
---

Your skill instructions...
EOF

# Reinstall
./install.sh --claude
```

### New Subagent
```bash
# Create subagent definition
cat > agents/subagents/my-agent.md << 'EOF'
---
name: my-agent
description: What this agent does
tools: Read, Grep, Glob, Bash
model: sonnet
---

Your agent instructions...
EOF

# Reinstall
./install.sh --claude
```

## Common Install Recipes

Install everything:
```bash
./install.sh --all
```

Install only Claude Code config:
```bash
./install.sh --claude
```

Reinstall after updating skills:
```bash
./install.sh --claude
```
