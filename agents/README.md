# Agents Configuration

Shared skills and subagents installable to Claude Code, Codex, OpenCode, Cursor, and pi.

## Structure

```
agents/
├── AGENTS.md                # Global instructions (symlinked into each harness)
├── subagents/               # Subagent definitions
│   ├── pr-description-gen.md
│   ├── security-scanner.md
│   ├── breaking-change-detector.md
│   ├── python-type-fixer.md
│   └── python-code-simplifier.md
└── skills/                  # Skills (51 total)
    ├── agent-browser/                    # Browser automation CLI for AI agents
    ├── audit-ai-code/                    # Audit AI-shaped backend code diffs for slop
    ├── audit-ai-frontend/                # Audit AI-looking frontend implementations
    ├── audit-ai-writing/                 # Audit AI-writing artifacts and citation issues
    ├── baseline/                         # Install quality baseline (linter, hooks, dead-code)
    ├── claude-review/                    # Second opinion via Claude Code CLI
    ├── clean-coder/                      # Invoked when user swears or is upset
    ├── clean-gone/                       # Delete local branches gone from remote
    ├── clean-worktrees/                  # Audit/clean agent worktrees safely
    ├── code-review-prompt/               # Generate code review prompt for current branch
    ├── code-simplifier/                  # Simplify recently modified code
    ├── codex-review/                     # Second opinion via OpenAI Codex CLI
    ├── de-slop/                          # Remove AI artifacts before PR
    ├── design-doc/                       # Create technical design documents
    ├── dogfood/                          # Exploratory test web app, structured bug report
    ├── emil-design-engineering/          # Design engineering principles
    ├── execute-plan/                     # Work through plan file task-by-task
    ├── garry-tan-code-review/            # Interactive opinionated code review
    ├── gh-address-pr-comments/           # Resolve PR review comments
    ├── gh-commit/                        # Conventional commit messages
    ├── gh-fix-ci/                        # Fix first failing CI check
    ├── gh-review-pr/                     # Review GitHub PR
    ├── gh-ship/                          # Commit, push, PR in one step
    ├── grill-me/                         # Stress-test plan via relentless interview
    ├── handoff/                          # Generate continuation prompt
    ├── humanize-ai-text/                 # Rewrite AI text to pass detectors
    ├── improve-codebase-architecture/    # Find deepening opportunities
    ├── iterate-forever/                  # Visual-reference-to-app loop
    ├── make-tests/                       # Add tests for current change
    ├── merge-conflicts/                  # Rebase, resolve conflicts, force-push
    ├── new-skill/                        # Create skill from conversation
    ├── office-hours/                     # YC-style forcing questions / brainstorm
    ├── pair-programming/                 # Senior engineer pairing mode
    ├── pre-pr/                           # Full pre-PR validation pipeline
    ├── prove-it-bug-fix/                 # Failing test before fix
    ├── qa/                               # Browser QA against plan file
    ├── qa-gstack/                        # QA test + fix loop
    ├── qa-gstack-only/                   # Report-only QA testing
    ├── rams/                             # Accessibility / visual design review
    ├── react-doctor/                     # Catch React issues early
    ├── self-improve/                     # Codex session-driven self-improvement
    ├── shopify-dev-theme/                # Dev theme from current branch
    ├── shopify-liquid-patterns/          # Liquid code patterns
    ├── shopify-theme-pull/               # Pull merchant content from live theme
    ├── skill-creator/                    # Create/edit/measure skills
    ├── smart-brevity/                    # Smart Brevity rewriting
    ├── subagent-orchestrator/            # Orchestrate sub-agents for long tasks
    ├── vercel-react-best-practices/      # React/Next.js performance patterns
    ├── web-animation-design/             # Web animation patterns
    ├── work-forever/                     # Highly autonomous long-running mode
    └── zoom-out/                         # Higher-level perspective on code
```

## Install

Run from repo root:

```bash
./install.sh --all                # everything
./install.sh --claude             # Claude Code only
./install.sh --codex              # Codex (~/.agents)
./install.sh --opencode           # OpenCode
./install.sh --cursor             # Cursor global
./install.sh --cursor-project     # Cursor project-local
./install.sh --pi                 # pi coding agent
./install.sh --all --dry-run      # preview
```

### What `--claude` installs

- `~/.claude/CLAUDE.md` (symlink to `agents/AGENTS.md`)
- `~/.claude/agents/*.md` (symlinks to `agents/subagents/*.md`)
- `~/.claude/skills/*` (symlinks to `agents/skills/*`)

## Available Skills

### Development Workflow

- `/design-doc` — Technical design document with implementation tasks and open questions
- `/execute-plan` — Work through a plan file task-by-task (`--commit-per-task`, `--commit-end-only`)
- `/qa` — Browser-based QA against `- [ ] QA:` items in a plan file
- `/handoff` — Continuation prompt for the next session
- `/de-slop` — Remove AI artifacts before PR
- `/make-tests` — Generate tests for current changes
- `/work-forever` — Highly autonomous long-running task mode
- `/iterate-forever` — Visual-reference-to-app loop with screenshot comparison
- `/dogfood` — Systematic bug hunt with structured repro evidence
- `/qa-gstack` — QA test + fix loop with before/after health scores
- `/qa-gstack-only` — Report-only QA, no code changes
- `/merge-conflicts` — Rebase onto main, resolve conflicts, force-push

### GitHub Workflow

- `/gh-ship` — Commit, push, open PR in one step
- `/gh-commit` — Imperative conventional commit message
- `/gh-review-pr` — Thorough PR review (correctness, tests, risk)
- `/gh-address-pr-comments` — Resolve open review comments
- `/gh-fix-ci` — Debug and fix first failing CI check
- `/clean-gone` — Remove local branches gone from remote
- `/clean-worktrees` — Audit and clean agent worktrees safely

### Code Quality and Review

- `/pre-pr` — Full validation pipeline (security, types, tests, breaking changes)
- `/rams` — Accessibility and visual design review against WCAG
- `/code-review-prompt` — Generate review prompt for another Claude session
- `/garry-tan-code-review` — Interactive opinionated review with sign-off
- `/codex-review` — Second opinion via OpenAI Codex CLI
- `/claude-review` — Second opinion via Claude Code CLI
- `/code-simplifier` — Simplify recently modified code
- `/baseline` — Install quality baseline (linter, formatter, hooks, dead-code scan)
- `/react-doctor` — Catch React issues after changes
- `/vercel-react-best-practices` — React/Next.js performance patterns
- `/audit-ai-code` — Triage AI-shaped backend code for duplicate helpers, broad excepts, hallucinated APIs
- `/audit-ai-frontend` — Triage AI-looking UI: generic aesthetics, weak copy, a11y gaps
- `/audit-ai-writing` — Residue checks for AI-writing artifacts and citation failures
- `/improve-codebase-architecture` — Find deepening opportunities toward deep modules

### Planning and Thinking

- `/grill-me` — Stress-test a plan via relentless interview until each branch resolves
- `/zoom-out` — Higher-level perspective on a section of code
- `/office-hours` — YC-style forcing questions or brainstorm mode
- `/subagent-orchestrator` — Coordinate sub-agents on complex long-horizon tasks
- `/pair-programming` — Senior engineer pairing with pushback and scope discipline
- `/prove-it-bug-fix` — Failing reproduction test before fixing

### Frontend and Design

- `/emil-design-engineering` — Polished, accessible web interface principles
- `/web-animation-design` — Animation patterns and performance
- `/shopify-liquid-patterns` — Liquid code patterns

### Shopify

- `/shopify-dev-theme` — Dev theme from current git branch
- `/shopify-theme-pull` — Pull merchant content from live theme

### Writing

- `/humanize-ai-text` — Rewrite AI text to sound natural / pass detectors
- `/smart-brevity` — Smart Brevity rewriting

### Browser Automation

- `/agent-browser` — Standalone browser CLI for navigation, forms, scraping, screenshots

### Meta

- `/new-skill` — Create a new skill from current conversation
- `/skill-creator` — Create, edit, evaluate, and benchmark skills
- `/self-improve` — Codex session-driven self-improvement
- `/clean-coder` — Invoked when user swears or is upset

## Available Subagents

### `pr-description-gen`
Auto-generate PR descriptions: summary, test plan, breaking changes, changelog.

### `security-scanner`
Scan for hardcoded secrets, SQL/command injection, SSRF, OWASP Top 10.

### `breaking-change-detector`
Detect breaking changes in API endpoints, schemas, migrations, configs.

### `python-type-fixer`
Modernize Python type annotations: `Optional[X]` → `X | None`, `List[X]` → `list[X]`, `Union[X, Y]` → `X | Y`.

### `python-code-simplifier`
Reduce complexity, remove duplicates, simplify error handling.

## Adding Custom Content

### New Skill

```bash
mkdir -p agents/skills/my-skill
cat > agents/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: What this skill does
---

Your skill instructions...
EOF

./install.sh --claude
```

### New Subagent

```bash
cat > agents/subagents/my-agent.md << 'EOF'
---
name: my-agent
description: What this agent does
tools: Read, Grep, Glob, Bash
model: sonnet
---

Your agent instructions...
EOF

./install.sh --claude
```
