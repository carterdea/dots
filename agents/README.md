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
└── skills/                  # Skills
    ├── agent-browser/                    # Browser automation CLI for AI agents
    ├── audit-ai-frontend/                # Audit AI-looking frontend implementations
    ├── baseline/                         # Install quality baseline (linter, hooks, dead-code)
    ├── claude-review/                    # Second opinion via Claude Code CLI
    ├── clean-coder/                      # Invoked when user swears or is upset
    ├── clean-worktrees/                  # Audit/clean agent worktrees and gone branches safely
    ├── code-simplifier/                  # Simplify recently modified code
    ├── codex-review/                     # Second opinion via OpenAI Codex CLI
    ├── de-slop/                          # Clean AI-shaped code before PR
    ├── design-doc/                       # Create technical design documents
    ├── dogfood/                          # Exploratory test web app, structured bug report
    ├── domain-model/                     # Grilling session that maintains CONTEXT.md + ADRs
    ├── emil-design-engineering/          # Design engineering principles
    ├── execute-plan/                     # Work through plan file task-by-task
    ├── gh-address-pr-comments/           # Watch PR comments and fix valid feedback
    ├── gh-commit/                        # Conventional commit messages
    ├── gh-fix-ci/                        # Fix first failing CI check
    ├── gh-review-pr/                     # Review GitHub PR
    ├── gh-ship/                          # Commit, push, PR in one step
    ├── grilling/                         # Relentless one-question-at-a-time planning interview
    ├── grill-me/                         # Stress-test plan via relentless interview
    ├── handoff/                          # Generate continuation prompt
    ├── humanize-ai-text/                 # Humanize AI-shaped writing and citation cleanup
    ├── improve-codebase-architecture/    # Find deepening opportunities
    ├── iterate-forever/                  # Visual-reference-to-app loop
    ├── make-tests/                       # Add tests for current change
    ├── merge-conflicts/                  # Rebase, resolve conflicts, force-push
    ├── loop-me/                          # Specify recurring workflows through grilling
    ├── pre-pr/                           # Project-appropriate PR validation and summary
    ├── prove-it-bug-fix/                 # Failing test before fix
    ├── qa/                               # Browser QA against plan file
    ├── rams/                             # Accessibility / visual design review
    ├── react-doctor/                     # Catch React issues early
    ├── react-native-skills/              # React Native and Expo performance patterns
    ├── self-improve/                     # Codex session-driven self-improvement
    ├── shopify-app-store-review/         # Shopify App Store review requirements
    ├── shopify-dev-theme/                # Dev theme from current branch
    ├── shopify-liquid-patterns/          # Liquid code patterns
    ├── shopify-payments-apps/            # Shopify payments app APIs and validation
    ├── shopify-polaris-admin-extensions/ # Polaris Admin UI extension code and validation
    ├── shopify-polaris-app-home/         # Polaris app home code and validation
    ├── shopify-storefront-graphql/       # Storefront GraphQL queries and validation
    ├── shopify-theme-pull/               # Pull merchant content from live theme
    ├── shopify-trello-delivery/          # Shopify Trello ticket delivery workflow
    ├── shopify-use-shopify-cli/          # Shopify CLI operational workflows
    ├── skill-creator/                    # Create/edit/measure skills
    ├── smart-brevity/                    # Smart Brevity rewriting
    ├── subagent-orchestrator/            # Orchestrate sub-agents for long tasks
    ├── trello-cli/                       # Drive Trello through the `trello-cli`
    ├── trello-delivery/                  # Trello ticket → reviewable PR (non-Shopify)
    ├── vercel-react-best-practices/      # React/Next.js performance patterns
    ├── web-animation-design/             # Web animation patterns
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

Skills with `package.json` get their local dependencies installed with `bun install` during any agent skill install target, so validation scripts run through the symlinked skill paths.

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
- `/de-slop` — Remove AI artifacts and clean AI-shaped code before PR
- `/make-tests` — Generate tests for current changes
- `/iterate-forever` — Visual-reference-to-app loop with screenshot comparison
- `/dogfood` — Systematic bug hunt with structured repro evidence
- `/merge-conflicts` — Rebase onto main, resolve conflicts, force-push

### GitHub Workflow

- `/gh-ship` — Commit, push, open PR in one step
- `/gh-commit` — Imperative conventional commit message
- `/gh-review-pr` — Thorough PR review (correctness, tests, risk)
- `/gh-address-pr-comments` — Watch PR comments and fix valid review feedback
- `/gh-fix-ci` — Debug and fix first failing CI check
- `/clean-worktrees` — Audit and clean agent worktrees and gone branches safely
- `/trello-delivery` — Ship a Trello ticket end to end as a reviewable PR (non-Shopify web apps). Requires the `trello-cli` binary from [Scale-Flow/trello-cli](https://github.com/Scale-Flow/trello-cli)

### Code Quality and Review

- `/pre-pr` — Project-appropriate validation, release-risk review, and PR summary
- `/rams` — Accessibility and visual design review against WCAG
- `/codex-review` — Second opinion via OpenAI Codex CLI
- `/claude-review` — Second opinion via Claude Code CLI
- `/code-simplifier` — Simplify recently modified code
- `/baseline` — Install quality baseline (linter, formatter, hooks, dead-code scan)
- `/react-doctor` — Catch React issues after changes
- `/react-native-skills` — React Native and Expo performance patterns
- `/vercel-react-best-practices` — React/Next.js performance patterns
- `/audit-ai-frontend` — Triage AI-looking UI: generic aesthetics, weak copy, a11y gaps
- `/improve-codebase-architecture` — Find deepening opportunities toward deep modules

### Planning and Thinking

- `/grill-me` — Stress-test a plan via relentless interview until each branch resolves
- `/grilling` — Relentless one-question-at-a-time planning interview
- `/loop-me` — Specify recurring workflows through grilling
- `/domain-model` — Grilling session that updates `CONTEXT.md` (glossary) and `docs/adr/` inline as decisions crystallize. Pairs with `/improve-codebase-architecture`
- `/zoom-out` — Higher-level perspective on a section of code
- `/subagent-orchestrator` — Coordinate sub-agents on complex long-horizon tasks
- `/prove-it-bug-fix` — Failing reproduction test before fixing

### Frontend and Design

- `/emil-design-engineering` — Polished, accessible web interface principles
- `/web-animation-design` — Animation patterns and performance
- `/shopify-liquid-patterns` — Liquid code patterns

### Shopify

- `/shopify-app-store-review` — Shopify App Store review requirements
- `/shopify-dev-theme` — Dev theme from current git branch
- `/shopify-payments-apps` — Shopify payments app APIs and validation
- `/shopify-polaris-admin-extensions` — Polaris Admin UI extension code and validation
- `/shopify-polaris-app-home` — Polaris app home code and validation
- `/shopify-storefront-graphql` — Storefront GraphQL queries, mutations, and validation
- `/shopify-theme-pull` — Pull merchant content from live theme
- `/shopify-trello-delivery` — Ship Shopify Trello tickets through PR, preview theme, screenshots, and Trello handoff. Requires the `trello-cli` binary from [Scale-Flow/trello-cli](https://github.com/Scale-Flow/trello-cli)
- `/shopify-use-shopify-cli` — Shopify CLI operational workflows

### Writing

- `/humanize-ai-text` — Humanize AI-shaped writing, audit LLM residue, and triage citations
- `/smart-brevity` — Smart Brevity rewriting

### Browser Automation

- `/agent-browser` — Standalone browser CLI for navigation, forms, scraping, screenshots

### External Tools

- `/trello-cli` — Drive Trello (boards, lists, cards, comments, checklists, labels) through the `trello-cli`. Requires the binary from [Scale-Flow/trello-cli](https://github.com/Scale-Flow/trello-cli)

### Meta

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
