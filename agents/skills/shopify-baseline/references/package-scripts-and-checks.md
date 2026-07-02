# Package Scripts And Checks

Use this when writing baseline files, package scripts, and agent instruction snippets.

## Files To Write

Copy these resources when missing:

- `scripts/run_silent.sh` from `scripts/run_silent.sh`
- `scripts/check.sh` from `scripts/check.sh`
- `lefthook.yml` from `resources/lefthook.shopify.yml`
- `.github/workflows/ci.yml` from `resources/github-actions.shopify-ci.yml`
- `.github/workflows/claude-code-review.yml` from `resources/github-actions.claude-code-review.yml`
- `.github/workflows/shopify-lighthouse-ci.yml` from `resources/github-actions.shopify-lighthouse-ci.yml` when shop secrets are available or the user wants the template
- `tests/accessibility/shopify-a11y.spec.ts` from `resources/playwright-a11y.spec.ts` when Playwright is absent or lacks axe coverage
- `playwright.config.ts` from `resources/playwright.config.shopify.ts` when Playwright has no config
- `vite.config.ts` from `resources/vite.config.shopify.ts` when converting frontend builds to Vite
- `.theme-check.yml` from `resources/theme-check.yml` when Theme Check has no config
- `biome.json` from `resources/biome.shopify.json` when Biome has no config
- `.fallowrc.jsonc` from `resources/fallow.shopify.jsonc` only when `src/` exists and fallow has no config
- `.shopifyignore` from `resources/shopifyignore.default` when missing
- `.env.example` from `resources/env.shopify.example` when missing

Append `resources/agent-instructions.snippet.md` to existing root `AGENTS.md`, `CLAUDE.md`, and `.cursor/rules/*.mdc`. Do not create agent instruction files from scratch unless asked.

The snippet is bounded by `<!-- shopify-baseline:run-silent -->` and `<!-- /shopify-baseline:run-silent -->`. If both markers exist, replace the full marked range. If an old install has only the opening marker, treat that open marker through the end of its block as the range and rewrite it with the bounded version.

Key upgrade idempotency on a `scripts/check.sh` mention, not merely `run_silent.sh`.

Resource templates default to Bun. In pnpm repos, rewrite `bun install`, `bun run`, and `bunx` to pnpm equivalents before writing. In GitHub Actions, replace Bun setup with `pnpm/action-setup` plus `actions/setup-node` with `cache: pnpm`.

## Package Scripts

Patch `package.json` with scripts that match installed tools. Preserve existing project scripts unless replacing an old equivalent.

Default shape:

```json
{
  "scripts": {
    "check": "bash scripts/check.sh",
    "check:theme": "shopify theme check",
    "check:biome": "biome check .",
    "check:type": "if [ -f tsconfig.json ]; then tsc --noEmit; else echo \"skipped: no tsconfig.json\"; fi",
    "check:dead-code": "if [ -d src ] && { ls .fallowrc.* fallow.* >/dev/null 2>&1 || node -e \"process.exit(require('./package.json').fallow ? 0 : 1)\" 2>/dev/null; }; then fallow dead-code; else echo \"skipped: fallow runs only when src/ + a fallow config exist\"; fi",
    "check:test": "if ls vitest.config.* >/dev/null 2>&1; then vitest run; else echo \"skipped: no vitest config\"; fi",
    "check:a11y": "if [ -n \"${BASE_URL:-}${SHOPIFY_PREVIEW_URL:-}\" ]; then playwright test tests/accessibility; else echo \"skipped: set BASE_URL or SHOPIFY_PREVIEW_URL for accessibility smoke tests\"; fi",
    "build": "vite build"
  }
}
```

The granular `check:*` bodies stay direct binary commands. `node_modules/.bin` resolution works under Bun and pnpm. Do not write `pnpm run biome check .`; that makes pnpm look for a script named `biome`.

`check` runs through `scripts/check.sh`, which sources `run_silent.sh`. Clean runs print one compact line per check; failures print full output. Checks that intentionally opt out, such as no preview URL or no `src/`, must say `skipped:` and exit 0 so `run_silent` can render an explicit skipped status.

CI runs `check:*` steps discretely because GitHub already collapses clean output.

## Local Hooks

Use fast staged checks on commit and full checks on push.

Pre-commit:

- Theme Check full-theme run when staged theme files changed. Theme Check supports `--path`, not staged file lists.
- Biome write/check on staged JS/TS/JSON/CSS files.

Pre-push:

- Theme Check full repo.
- Biome full repo.
- Typecheck if `tsconfig.json` exists.
- Fallow dead-code if `src/` and fallow config exist.
- Vitest if configured.
- Playwright accessibility only if `BASE_URL` is set.

Do not run Shopify Lighthouse CI locally by default.
