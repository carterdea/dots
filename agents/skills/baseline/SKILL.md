---
name: baseline
description: Quality floor installer for TS/JS, Python, and Ruby repos.
disable-model-invocation: true
---

# Baseline

Install a light-touch quality floor on a repo. Detect the stack, add the missing standard tools, wire local hooks and CI, install Portless, and make quiet checks discoverable to future agents.

Safe to re-run: skip what is already configured and report it.

## Principles

- **Light-touch:** if a config already exists, log `already configured: <path>` and do not merge, diff, overwrite, or modernize it.
- **Honest debt:** install the guardrails; do not fix the issues they surface. Report failing checks and counts so the repo's real debt is visible.
- **One agent file:** `CLAUDE.md` is canonical; `AGENTS.md` is only a relative symlink to it.
- **Project manager wins:** use the existing lockfile/package manager. Do not rewrite lockfiles or migrate managers.
- **Quiet checks:** install `scripts/run_silent.sh` and point agent instructions at it so success is compact and failure is diagnostic.

## References

Read only the reference branch the detected repo needs:

- TS/JS, Python, Ruby tool choices, framework detection, linter/typecheck/fallow/lefthook details: [`references/stacks.md`](references/stacks.md)
- `run_silent.sh`, agent-instruction snippets, Portless, and produced files: [`references/backpressure-portless.md`](references/backpressure-portless.md)
- GitHub Actions and monorepo layout: [`references/github-actions-monorepos.md`](references/github-actions-monorepos.md)

## Steps

### 1. Detect the repo

Detect stacks by marker files:

- `package.json` -> TS / JS
- `pyproject.toml` or `requirements.txt` -> Python
- `Gemfile` -> Ruby

Detect framework and package-manager details using [`references/stacks.md`](references/stacks.md). In mixed repos, handle each workspace with its own stack rules and keep hooks at the repo root.

Completion criterion: every detected stack/workspace has a package manager, framework guess, and existing-tool inventory.

### 2. Install missing toolchain pieces

For each detected stack, install only the missing baseline tools:

- TS / JS: Biome, fallow, lefthook.
- Python: Ruff, basedpyright or pyright, lefthook.
- Ruby: Rubocop plus framework gems, lefthook.
- All stacks: global Portless, only if missing.

Use the exact commands, skip rules, and per-framework presets in [`references/stacks.md`](references/stacks.md). Before installing or pinning dependency versions, check the current version through the appropriate docs/search path; do not assume latest.

Completion criterion: each missing tool is installed or explicitly reported as skipped/already configured.

### 3. Wire hooks

Create one root `lefthook.yml` if no lefthook config exists. Use fast staged checks on commit and full checks on push:

- Pre-commit: formatter/linter staged-file fixes where the tool supports it.
- Pre-push: typecheck, dead-code scan, and full test suite when present.

For monorepos, scope hook globs and commands per workspace using [`references/github-actions-monorepos.md`](references/github-actions-monorepos.md).

Completion criterion: `lefthook.yml` exists or was skipped because an existing hook config already owns the repo.

### 4. Add quiet-check support

Copy `scripts/run_silent.sh` into `scripts/run_silent.sh` if missing and make it executable. Append the stack-specific run-silent and Portless snippets to the canonical agent instructions using [`references/backpressure-portless.md`](references/backpressure-portless.md).

Reconcile agent instructions first:

- If `AGENTS.md` is a real file, stop only this reconcile path and log: `AGENTS.md is a real file — merge it into CLAUDE.md, replace it with ln -s CLAUDE.md AGENTS.md, then re-run baseline.`
- Otherwise create `CLAUDE.md` if missing and create a relative `AGENTS.md -> CLAUDE.md` symlink if missing.

Append `.gitignore` entries for `test-results/`, `/qa/screenshots/`, and `/qa/reports/` if absent.

Completion criterion: the wrapper exists, QA artifacts are ignored, and the canonical agent file either contains the right snippets or has a clear manual-reconcile blocker.

### 5. Install Portless

If `portless` is not on `PATH`, install it globally. Gate `portless trust` so it only runs in an interactive, non-CI shell. Use [`references/backpressure-portless.md`](references/backpressure-portless.md) for the exact commands and caveats.

Completion criterion: Portless is available or the install failure is reported with the command that failed.

### 6. Add CI

If the remote is GitHub and `.github/workflows/` has no workflow files, write `.github/workflows/ci.yml` from the matching resource template. Detect the default branch and substitute it into the workflow.

If any workflow already exists, log `GitHub Actions already configured, skipping.` Do not merge or overwrite.

Use [`references/github-actions-monorepos.md`](references/github-actions-monorepos.md) for package-manager substitutions, cache rules, detected-test inclusion, and monorepo job shape.

Completion criterion: CI is created from the matching template or explicitly skipped because workflows already exist or the remote is not GitHub.

### 7. Verify

Run the hook commands for each detected stack:

```bash
# TS/JS
bunx lefthook run pre-commit
bunx lefthook run pre-push

# Python
uv run lefthook run pre-commit
uv run lefthook run pre-push

# Ruby
bundle exec lefthook run pre-commit
bundle exec lefthook run pre-push
```

If checks fail, separate setup failures from inherited project debt. Do not fix the debt during baseline.

Completion criterion: report tools installed, tools skipped, hooks wired, CI status, and verification results.
