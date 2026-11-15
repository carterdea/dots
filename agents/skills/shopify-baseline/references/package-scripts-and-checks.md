# Package Scripts And Checks

Use this when writing baseline files, package scripts, and AGENTS.md.

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

Resource templates default to Bun. In pnpm repos, rewrite `bun install`, `bun run`, and `bunx` to pnpm equivalents before writing. In GitHub Actions, replace Bun setup with `pnpm/action-setup` plus `actions/setup-node` with `cache: pnpm`.

## AGENTS.md

`AGENTS.md` is the only agent file; Claude Code, Codex, Cursor, and the rest read it. Never create `CLAUDE.md`, a symlink to it, or `.cursor/rules` files, and leave existing ones alone.

The `## Working here` section of `resources/agents-md.template.md` is bounded by `<!-- shopify-baseline:run-silent -->` and `<!-- /shopify-baseline:run-silent -->`. Rewrite `<pm>` to `bun` or `pnpm`, and keep only rows for checks that exist.

- `AGENTS.md` exists with both markers: replace the marked range. With only the opening marker (an old install), treat that marker through the end of its block as the range. With neither, append the marked section. Touch nothing else in the file.
- Only a real `CLAUDE.md` exists: log `CLAUDE.md found — git mv CLAUDE.md AGENTS.md, then re-run shopify-baseline.` and skip this step.
- Neither exists: write `AGENTS.md` from the template. Draft Why it exists, Principles, and How it fits together from the README, `shopify.theme.toml`, `layout/theme.liquid`, and the build config. Drop any section the repo cannot answer and report it as an open question; never invent a client, goal, or status. Link only docs that exist, and remove the template's HTML comments.

## Package Scripts

Patch `package.json` with scripts that match installed tools. Preserve existing project scripts unless replacing an old equivalent.

Default shape:

```json
{
  "scripts": {
    "check": "bash scripts/check.sh",
    "check:theme": "shopify theme check",
    "check:biome": "biome check .",
    "check:type": "if [ -f tsconfig.json ]; then tsrs --noEmit --fast; else echo \"skipped: no tsconfig.json\"; fi",
    "check:type:ci": "if [ -f tsconfig.json ]; then tsc --noEmit; else echo \"skipped: no tsconfig.json\"; fi",
    "check:dead-code": "if [ -d src ] && { ls .fallowrc.* fallow.* >/dev/null 2>&1 || node -e \"process.exit(require('./package.json').fallow ? 0 : 1)\" 2>/dev/null; }; then fallow dead-code --quiet --fail-on-issues; else echo \"skipped: fallow runs only when src/ + a fallow config exist\"; fi",
    "check:test": "if ls vitest.config.* >/dev/null 2>&1; then vitest run; else echo \"skipped: no vitest config\"; fi",
    "check:a11y": "if [ -n \"${BASE_URL:-}${SHOPIFY_PREVIEW_URL:-}\" ]; then playwright test tests/accessibility; else echo \"skipped: set BASE_URL or SHOPIFY_PREVIEW_URL for accessibility smoke tests\"; fi",
    "build": "vite build"
  }
}
```

The granular `check:*` bodies stay direct binary commands. `node_modules/.bin` resolution works under Bun and pnpm. Do not write `pnpm run biome check .`; that makes pnpm look for a script named `biome`.

`check` runs through `scripts/check.sh`, which sources `run_silent.sh`. Clean runs print one compact line per check; failures print full output. Checks that intentionally opt out, such as no preview URL or no `src/`, must say `skipped:` and exit 0 so `run_silent` can render an explicit skipped status.

CI gives every check its own job so each reports as its own PR status check. Most jobs run the matching `check:*` script; `theme-check` is the exception, using `shopify/theme-check-action` instead of `check:theme`.

## Local Hooks

Use fast staged checks on commit and full checks on push.

Pre-commit:

- Theme Check full-theme run when staged theme files changed. Theme Check supports `--path`, not staged file lists.
- Biome write/check on staged JS/TS/JSON/CSS files.
- Typecheck (tsrs) if `tsconfig.json` exists and TS files are staged.

Pre-push:

- Theme Check full repo.
- Biome full repo.
- Fallow dead-code if `src/` and fallow config exist.
- Vitest if configured.
- Playwright accessibility only if `BASE_URL` is set.

Do not run Shopify Lighthouse CI locally by default.
