---
name: shopify-baseline
description: Install or upgrade a quality baseline for Shopify theme repos. Use this whenever the user asks to add Shopify theme linting, Biome, Theme Check, Playwright accessibility checks, Vitest, Vite build tooling, lefthook hooks, GitHub Actions CI, Shopify Lighthouse CI, Claude Code PR review workflows, or a context-efficient run_silent.sh setup across Shopify sites.
user-invocable: true
---

# Shopify Baseline

Set up a reusable quality floor for Shopify Online Store 2.0 theme repos: Theme Check for Liquid/theme rules, Biome for JS/TS/JSON/CSS-adjacent checks, Vite for frontend source builds, Playwright + axe for rendered accessibility smoke tests, optional Vitest for complex JS, lefthook for local gates, GitHub Actions for CI, Shopify Lighthouse CI when shop secrets exist, Claude Code PR review automation, and `scripts/run_silent.sh` for context-efficient agent output.

## Principles

- Use existing repo conventions when they are already good: pnpm stays pnpm; otherwise use Bun.
- Do not use npm or yarn for new installs.
- Before installing, pinning, or upgrading dependencies, check current versions with context7 or Exa. Never assume latest.
- Keep Shopify assets safe: Vite must output to `assets/` with `emptyOutDir: false`.
- Do not run dev servers unless the user explicitly asks. Browser checks require an existing `BASE_URL`, `SHOPIFY_PREVIEW_URL`, or Shopify Lighthouse CI benchmark store.
- Keep the setup idempotent: skip existing configs unless the workflow explicitly says to upgrade them.
- When editing existing GitHub Actions, patch the smallest surface needed. Do not overwrite unrelated deployment workflows.
- Before changing files, do a dry-run inventory: report detected tools, missing baseline pieces, proposed files/scripts/workflows, and which changes require confirmation.

## Resolve Bundled Resources

Resolve resource paths relative to the directory containing this `SKILL.md`. In Codex, expand the skill path from the loaded skill metadata. In shell helpers, use an explicit variable:

```bash
SKILL_DIR="/absolute/path/to/agents/skills/shopify-baseline"
```

Then copy resources from `$SKILL_DIR/resources/...` and `$SKILL_DIR/scripts/...`. Do not assume the current working directory is the skill directory.

## Detect The Repo

Treat the target as a Shopify theme if any of these exist:

- `layout/theme.liquid`
- `config/settings_schema.json`
- `sections/*.liquid`
- `templates/*.json`
- `shopify.theme.toml`

Detect package manager:

- `pnpm-lock.yaml` -> pnpm
- otherwise -> Bun, even if old npm/yarn files exist. Report stale `package-lock.json` or `yarn.lock` and remove only when the user explicitly asks for package-manager cleanup.

Detect existing tooling:

- Theme Check: `.theme-check.yml`, `.theme-check.yaml`, or package/scripts calling `shopify theme check`
- Biome: `biome.json` or `biome.jsonc`
- Vite: `vite.config.*` or `vite` dependency
- Playwright: `playwright.config.*` or `@playwright/test`
- Vitest: `vitest.config.*`, `vitest` dependency, or test scripts
- Hooks: `lefthook.yml`, `lefthook.yaml`, or `.lefthook.yml`
- Claude Code Action: `.github/workflows/*` containing `anthropics/claude-code-action`
- Shopify Lighthouse CI: `.github/workflows/*` containing `shopify/lighthouse-ci-action`

If the theme is not at the repository root, stop after detection and propose a root strategy before writing files. Current default is one Shopify theme per repo; future monorepos should put hooks/workflows at repo root and theme configs/scripts under the theme directory.

## Install Dependencies

Check current versions first, then install only missing packages.

Default dev dependencies:

- `@shopify/cli` for reproducible `shopify theme check`
- `@biomejs/biome`
- `vite` when source JS/CSS build tooling exists or should be converted
- `typescript` only when TS source or `tsconfig.json` exists
- `lefthook`
- `@playwright/test`
- `@axe-core/playwright`
- `vitest` only when the theme has meaningful source modules or existing tests

Commands after resolving versions:

```bash
# Bun default
bun add -d --exact @shopify/cli@<version> @biomejs/biome@<version> lefthook@<version> @playwright/test@<version> @axe-core/playwright@<version>

# Existing pnpm repo
pnpm add -D --save-exact @shopify/cli@<version> @biomejs/biome@<version> lefthook@<version> @playwright/test@<version> @axe-core/playwright@<version>
```

Add `vite`, `typescript`, and `vitest` only when detected or requested.

After adding Playwright, install Chromium for local and CI runs:

```bash
bunx playwright install chromium
# pnpm repo:
pnpm exec playwright install chromium
```

## Files To Write

Copy these resources from this skill into the target repo when missing:

- `scripts/run_silent.sh` from `scripts/run_silent.sh`
- `lefthook.yml` from `resources/lefthook.shopify.yml`
- `.github/workflows/ci.yml` from `resources/github-actions.shopify-ci.yml`
- `.github/workflows/claude-code-review.yml` from `resources/github-actions.claude-code-review.yml`
- `.github/workflows/shopify-lighthouse-ci.yml` from `resources/github-actions.shopify-lighthouse-ci.yml` when shop secrets are available or the user wants the template
- `tests/accessibility/shopify-a11y.spec.ts` from `resources/playwright-a11y.spec.ts` when Playwright is absent or lacks axe coverage
- `playwright.config.ts` from `resources/playwright.config.shopify.ts` when Playwright has no config
- `vite.config.ts` from `resources/vite.config.shopify.ts` when converting frontend builds to Vite
- `.theme-check.yml` from `resources/theme-check.yml` when Theme Check has no config

Append `resources/agent-instructions.snippet.md` to existing root `AGENTS.md`, `CLAUDE.md`, and `.cursor/rules/*.mdc` if they do not already mention `run_silent.sh`. Do not create agent instruction files from scratch unless the user asks.

Resource templates default to Bun. In pnpm repos, rewrite `bun install`, `bun run`, and `bunx` to the pnpm equivalents before writing the file.

## Package Scripts

Patch `package.json` with scripts that match installed tools. Preserve existing project scripts unless replacing an old equivalent.

Use the detected package manager when composing scripts:

- Bun repo: `<run>` is `bun run`
- pnpm repo: `<run>` is `pnpm run`

Default script shape after substitution:

```json
{
  "scripts": {
    "check": "<run> check:theme && <run> check:biome && <run> check:type && <run> check:test && <run> check:a11y",
    "check:theme": "shopify theme check",
    "check:biome": "biome check .",
    "check:type": "if [ -f tsconfig.json ]; then tsc --noEmit; fi",
    "check:test": "if ls vitest.config.* >/dev/null 2>&1; then vitest run; fi",
    "check:a11y": "if [ -n \"${BASE_URL:-}${SHOPIFY_PREVIEW_URL:-}\" ]; then playwright test tests/accessibility; else echo \"skipped: set BASE_URL or SHOPIFY_PREVIEW_URL for accessibility smoke tests\"; fi",
    "build": "vite build"
  }
}
```

For pnpm repos, the script body should use `pnpm run ...`; for Bun repos, use `bun run ...`. Do not use npm or yarn as the package-manager fallback.

Use `scripts/run_silent.sh` for composite CI or agent-facing scripts:

```bash
source scripts/run_silent.sh
run_silent "theme check" bun run check:theme
run_silent "biome" bun run check:biome
run_silent "typecheck" bun run check:type
run_silent "vitest" bun run check:test
run_silent "playwright axe" bun run check:a11y
```

## Vite Conversion

When old frontend build tooling exists (`webpack`, `rollup`, `gulp`, `parcel`, bespoke `esbuild`, or hand-written bundling scripts), propose a Vite migration but do not perform it without explicit user confirmation.

Confirmation should include:

- detected current build tool
- source entry points
- expected output files in `assets/`
- Liquid asset references that may need to change
- validation commands that will prove the migration

Rules:

- Preserve current source entry names where possible.
- Output compiled assets into Shopify `assets/`.
- Set `emptyOutDir: false` so Vite never deletes merchant/theme assets.
- Keep filenames stable if Liquid references them directly.
- Do not rewrite Liquid asset references unless filenames change.
- Keep Vite config small. Add plugins only when the repo already needs them.

Use `resources/vite.config.shopify.ts` as the starting template, then adapt entries to the repo.

## Accessibility Baseline

Default accessibility gate:

- Playwright + `@axe-core/playwright`
- Scan rendered pages from `BASE_URL`
- Use WCAG A/AA tags: `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, `wcag22aa` when supported
- Cover home, collection, product, cart, search, mobile navigation, drawer/modal states when URLs/selectors are known
- Configure scanned paths with `SHOPIFY_A11Y_PATHS`, a comma-separated list such as `/,/collections/all,/products/example-product`

Do not add ESLint only for accessibility if the repo is Biome-first and mostly Liquid. Consider `pa11y-ci` or `html-validate` only as optional extensions when the user asks for deeper URL/sitemap or rendered-HTML validation.

If a preview URL is available, use the browser to inventory important pages before finalizing `SHOPIFY_A11Y_PATHS`. Do not consider the accessibility baseline complete until it covers at least homepage, one collection page, and one product page. Then propose any obvious high-traffic footer links, search, cart, account, and landing pages surfaced in navigation before hardcoding the path list in repo config.

## GitHub Actions

Create or update three separate workflow surfaces:

1. `ci.yml`
   - Runs static checks on every PR and pushes to the default branch.
   - Substitute the detected default branch instead of assuming `main`.
   - Runs Playwright axe only when `SHOPIFY_PREVIEW_URL` is available.
   - Runs Vitest only when configured.
   - Pin GitHub Actions to full commit SHAs after resolving the current latest tag or release. Resource templates include pinned refs as of May 23, 2026; refresh them when installing later.

2. `shopify-lighthouse-ci.yml`
   - Uses `shopify/lighthouse-ci-action@v1`.
   - Requires benchmark store secrets: `SHOP_STORE`, `SHOP_CLIENT_ID`, `SHOP_CLIENT_SECRET`.
   - `access_token` is legacy for apps created before January 2026; prefer `client_id` and `client_secret`.
   - Runs homepage plus product and collection pages; set `SHOPIFY_LIGHTHOUSE_PRODUCT_HANDLE` and `SHOPIFY_LIGHTHOUSE_COLLECTION_HANDLE` repository variables for stable representative pages, otherwise the action defaults to the first product/collection.
   - Keep initial thresholds realistic, then raise after the repo is clean.

3. `claude-code-review.yml`
   - Uses `anthropics/claude-code-action@v1`.
   - Requires `ANTHROPIC_API_KEY` unless the repo uses another supported auth provider.
   - Use `prompt` for review instructions.
   - Use `claude_args: --append-system-prompt ...` for extra behavioral framing.
   - Upgrade old beta workflows:
     - `@beta` -> `@v1`
     - remove `mode`
     - `direct_prompt` / `override_prompt` -> `prompt`
     - `custom_instructions` -> `claude_args: --append-system-prompt`
     - `model`, `max_turns`, `allowed_tools`, `disallowed_tools` -> `claude_args`

Claude review prompt must ask for normal code review plus Shopify theme best practices and accessibility issues. Do not include private client risk rationale in the prompt.

## Upgrade Existing Baselines

When asked to upgrade, compare the repo's current setup against this skill's baseline criteria, then propose the smallest set of improvements to close gaps. Treat upgrade as a review-and-patch workflow, not a wholesale replacement.

Check:

- package manager and installed tool versions
- Theme Check config and scripts
- Biome config and scripts
- Vite build path and asset output safety
- Playwright/axe coverage and `SHOPIFY_A11Y_PATHS`
- optional Vitest presence where complex JS exists
- lefthook local gates
- GitHub Actions CI, Lighthouse CI, action SHA pinning, and Claude Code v1 usage
- `scripts/run_silent.sh` and agent-instruction discoverability

Report proposed changes first. Patch existing files in place only after the user confirms any risky migration, especially build-tool conversions.

## Local Hooks

Use fast staged checks on commit and full checks on push.

- Pre-commit:
  - Theme Check full-theme run when staged theme files changed. Shopify Theme Check supports `--path` for theme root, not staged file lists.
  - Biome write/check on staged JS/TS/JSON/CSS files
- Pre-push:
  - Theme Check full repo
  - Biome full repo
  - Typecheck if `tsconfig.json` exists
  - Vitest if configured
  - Playwright accessibility only if `BASE_URL` is set

Do not run Shopify Lighthouse CI locally by default.

## Verify

Run quiet checks, not dev servers or builds unless the user asked for build verification.

```bash
# Bun
bunx lefthook run pre-commit
bunx lefthook run pre-push

# pnpm
pnpm exec lefthook run pre-commit
pnpm exec lefthook run pre-push
```

If existing repo failures block verification, report the failing command and whether it is from touched setup or inherited project debt.

## Report Back

Summarize:

- tools installed
- configs added
- workflows created or upgraded
- checks run and results
- skipped browser/Lighthouse checks due to missing URL or secrets
- unresolved questions, if any
