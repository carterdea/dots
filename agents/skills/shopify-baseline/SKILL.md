---
name: shopify-baseline
description: Quality floor installer for Shopify Online Store 2.0 theme repos.
disable-model-invocation: true
---

# Shopify Baseline

Install or upgrade a light-touch quality floor for Shopify Online Store 2.0 theme repos: Theme Check, Biome, Playwright axe, optional Vite/Vitest/fallow, lefthook, CI, Shopify Lighthouse CI, Claude Code review, `scripts/check.sh`, `run_silent.sh`, Theme Access handling, and `.shopifyignore`.

## Principles

- **Light-touch:** use existing conventions when sound; pnpm stays pnpm, otherwise use Bun. Do not use npm or yarn for new installs.
- **Honest debt:** install the baseline; do not fix the failures it exposes. Report failing checks and counts.
- **Asset safety:** Vite outputs to `assets/` with `emptyOutDir: false`.
- **No surprise servers:** do not run dev servers unless asked. Browser checks require an existing `BASE_URL`, `SHOPIFY_PREVIEW_URL`, or benchmark store.
- **Patch, don't replace:** patch existing GitHub Actions/configs narrowly and preserve unrelated deployment workflows.
- **Dry-run first:** before changing files, report detected tools, missing baseline pieces, proposed files/scripts/workflows, and changes needing confirmation.

## References

Read only the branch needed for the current repo:

- Theme Access secrets, `.env`, `.gitignore`, and `.shopifyignore`: [`references/theme-access-and-ignore-files.md`](references/theme-access-and-ignore-files.md)
- Package scripts, `scripts/check.sh`, `run_silent.sh`, and files to write: [`references/package-scripts-and-checks.md`](references/package-scripts-and-checks.md)
- Biome, Fallow, Vite, and accessibility rules: [`references/tooling-rules.md`](references/tooling-rules.md)
- GitHub Actions, Shopify Lighthouse CI, and Claude Code review: [`references/github-actions.md`](references/github-actions.md)

## Steps

### 1. Resolve resources

Resolve paths relative to this skill directory:

```bash
SKILL_DIR="/absolute/path/to/agents/skills/shopify-baseline"
```

Copy from `$SKILL_DIR/resources/...` and `$SKILL_DIR/scripts/...`; do not assume the current working directory is the skill directory.

Completion criterion: `SKILL_DIR` is known and resource copies will use absolute resolved paths.

### 2. Detect the repo

Treat the target as a Shopify theme if any of these exist:

- `layout/theme.liquid`
- `config/settings_schema.json`
- `sections/*.liquid`
- `templates/*.json`
- `shopify.theme.toml`

Detect package manager:

- `pnpm-lock.yaml` -> pnpm
- otherwise -> Bun, even if stale npm/yarn lockfiles exist. Report stale lockfiles and remove only when explicitly asked.

Inventory existing tooling:

- Theme Check config/action/script.
- Biome.
- Vite.
- Playwright and axe coverage.
- Vitest.
- Fallow, gated by bundled `src/` source.
- Lefthook.
- Claude Code Action.
- Shopify Lighthouse CI.
- `shopify.theme.toml` environments and committed `shptka_` secrets.
- `.shopifyignore`.

If the theme is not at the repository root, stop after detection and propose a root strategy before writing files.

Completion criterion: repo shape, package manager, existing tools, source layout, and risky migrations are known.

### 3. Propose the baseline delta

Before edits, report:

- tools to install or skip
- config/scripts/workflows to create or patch
- existing configs that will be left alone
- risky changes requiring confirmation, especially build-tool/Vite conversion or non-root theme layout
- secret handling findings from [`references/theme-access-and-ignore-files.md`](references/theme-access-and-ignore-files.md)

Completion criterion: the user has enough information to see what will change before files are touched.

### 4. Install missing dependencies

Check current versions before installing or pinning. Install only missing packages.

Default dev dependencies:

- `@shopify/cli`
- `@biomejs/biome`
- `lefthook`
- `@playwright/test`
- `@axe-core/playwright`

Add only when detected or requested:

- `vite`
- `typescript`
- `vitest`
- `fallow` only when bundled `src/` source exists

Use exact versions and the package-manager command from the repo. After adding Playwright, install Chromium with the matching package runner.

Completion criterion: package changes are limited to missing baseline dependencies and optional tools are only installed when their gate is met.

### 5. Write or patch baseline files

Use [`references/package-scripts-and-checks.md`](references/package-scripts-and-checks.md) for the file list and package script shape. Copy bundled resources when files are missing; patch existing files only where the reference explicitly says to reconcile.

Always preserve Shopify-managed theme data:

- Do not let Biome format `config/`, `locales/`, `layout/`, `sections/`, `snippets/`, `blocks/`, or `templates/`.
- Do not default-ignore `config/settings_data.json` in `.shopifyignore`.
- Do not write tokens into tracked files.

Completion criterion: all missing baseline files are written, existing files are respected, and Shopify-managed files are protected from formatter/deploy churn.

### 6. Handle Theme Access and ignore files

When `shopify.theme.toml` exists, follow [`references/theme-access-and-ignore-files.md`](references/theme-access-and-ignore-files.md):

- migrate committed `shptka_` passwords to `.env`
- ensure `.env` is untracked before writing secrets
- write `.env.example`
- keep `.env.example` unignored
- create or reconcile `.shopifyignore`

Completion criterion: secrets are not committed, leaked secrets are called out for rotation, and Shopify CLI push/pull ignores only the intended repo files.

### 7. Configure tool rules

Apply the rules in [`references/tooling-rules.md`](references/tooling-rules.md):

- Biome owns JS/TS and repo JSON only; Theme Check owns Liquid and Shopify-managed JSON.
- Fallow runs only against bundled `src/` module graphs.
- Vite conversion needs confirmation.
- Accessibility baseline uses Playwright axe and skips cleanly without a preview URL.

Completion criterion: tool configs do not fight Shopify theme files and optional scanners are gated to avoid false positives.

### 8. Add or upgrade workflows

Use [`references/github-actions.md`](references/github-actions.md) for:

- `ci.yml`
- optional `shopify-lighthouse-ci.yml`
- `claude-code-review.yml`

Patch narrowly. Dedupe GitHub Actions Theme Check steps in CI but keep local scripts/hooks.

Completion criterion: workflow surfaces are present or intentionally skipped, default branch placeholders are replaced, and unrelated workflows are preserved.

### 9. Verify

Run quiet checks, not dev servers or builds unless the user asked for build verification:

```bash
# Bun
bunx lefthook run pre-commit
bunx lefthook run pre-push

# pnpm
pnpm exec lefthook run pre-commit
pnpm exec lefthook run pre-push
```

If existing failures block verification, report the failing command and whether it is setup breakage or inherited project debt.

Completion criterion: report tools installed, configs added or patched, workflows created or upgraded, checks run, skipped browser/Lighthouse checks, and unresolved questions.
