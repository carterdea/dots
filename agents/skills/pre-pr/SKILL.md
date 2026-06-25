---
name: pre-pr
description: Run project-appropriate validation before opening a PR, then draft the PR summary.
user-invocable: true
---

# Pre-PR

Run the checks this project already defines, inspect the change for release risk, and prepare a clear pull request description. This skill is stack-agnostic: do not assume Python, TypeScript, Ruby, or any particular directory layout.

## Principles

- Prefer the repo's own quality gates over invented commands.
- If `lefthook` is configured, treat it as the primary local gate; baseline-managed repos put the right stack checks there.
- Detect stacks and workspaces from manifests before choosing commands.
- Keep checks proportional to the diff. Run targeted checks for small changes, broader checks for shared code, migrations, auth, payments, data access, or public APIs.
- Do not run dev servers or build commands unless the project docs, scripts, or user explicitly require them for PR validation.
- If a check fails, stop and report the failing command plus the smallest useful output. Fix only when the user asked for a fix, or when the fix is clearly part of the current task.

## 1. Gather Context

Run:

```bash
git branch --show-current
git status --short
git diff --stat
base_ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo main)"
git diff --name-only "$base_ref"...HEAD
```

Also read project guidance when present: `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `README.md`, and package-specific docs touched by the diff.

## 2. Detect Existing Gates

Look for validation already wired by the repo:

- Hooks: `lefthook.yml`, `.lefthook.yml`, `.husky/`, `pre-commit-config.yaml`.
- Scripts: `package.json`, `pyproject.toml`, `Gemfile`, `justfile`, `Makefile`, `Taskfile.yml`, `bin/`, `scripts/`.
- CI: `.github/workflows/`, `.gitlab-ci.yml`, Buildkite, CircleCI, or project-specific CI files.
- Configured tools: linters, formatters, typecheckers, test runners, dead-code scanners, security scanners, migration checks.

If `lefthook` exists, prefer:

```bash
lefthook run pre-commit
lefthook run pre-push
```

Use the repo's package-manager wrapper when needed, such as `bunx`, `pnpm exec`, `uv run`, or `bundle exec`.

## 3. Choose Checks By Change Type

Use the repo's own commands for these categories when available:

- Formatting and linting for changed languages.
- Typechecking or static analysis for typed code.
- Unit tests for touched behavior.
- Integration, browser, or end-to-end tests for user flows and cross-service changes.
- Migration/schema validation for database, API, GraphQL, protocol, or config changes.
- Security checks for auth, authorization, secrets, payments, file upload, shell execution, SSRF, SQL, or dependency changes.
- Accessibility and visual checks for UI changes.
- Documentation or generated artifact checks when docs, schemas, SDKs, or snapshots changed.

Do not invent missing infrastructure. If a repo has no obvious check for a category, note the gap instead of manufacturing a one-off command.

## 4. Review Release Risk

Inspect the diff for:

- Breaking API, schema, config, environment variable, or CLI changes.
- Data migrations, backfills, irreversible writes, or changed defaults.
- Permission, authentication, authorization, billing, or privacy behavior.
- Background jobs, scheduled tasks, queues, retries, cache invalidation, and idempotency.
- Error handling and rollback paths.
- User-facing copy, empty states, loading states, and failure states.
- Missing or stale tests around changed behavior.

Call out risks in the PR body even when checks pass.

## 5. Final Output

Before opening the PR, provide:

- Checks run, with pass/fail status.
- Checks intentionally skipped and why.
- Remaining risks or unresolved questions.
- A concise PR title and body.

PR body template:

```markdown
## Summary
- ...

## Validation
- ...

## Risks / Notes
- ...
```

Omit empty sections. Keep it factual; do not invent metrics, case studies, or test coverage.
