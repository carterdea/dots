---
name: shopify-baseline
description: Install or upgrade a quality baseline for Shopify Online Store 2.0 theme repos — Theme Check, Biome, Vite, Playwright + axe accessibility, optional Vitest, fallow dead-code, lefthook hooks, GitHub Actions CI, Shopify Lighthouse CI, Claude Code PR review, a context-efficient run_silent.sh wrapper, Theme Access token handling via .env, and a .shopifyignore, with sane defaults.
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
- **Install the baseline; do not fix what it surfaces.** Setting up the tooling will light up pre-existing Biome, Theme Check, typecheck, test, and accessibility failures — leave them failing. The point is an honest CI signal that shows the real debt; auto-fixing it here hides what needs attention. Report the failing checks and counts, and do the actual fixes in follow-up sessions. (Formatting that lefthook applies to *staged* files on commit is fine; sweeping repo-wide fixes are not.)

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
- Theme Check Action: `.github/workflows/*` containing `shopify/theme-check-action`
- Biome: `biome.json` or `biome.jsonc`
- Vite: `vite.config.*` or `vite` dependency
- Playwright: `playwright.config.*` or `@playwright/test`
- Vitest: `vitest.config.*`, `vitest` dependency, or test scripts
- Fallow (dead-code): `fallow.json`, `.fallowrc.json`, `.fallowrc.jsonc`, `fallow.toml`, or a `fallow` key in `package.json`
- Bundled JS source: a `src/` directory with `.ts`/`.tsx`/`.js`/`.jsx` files. This is the gate for fallow — without it, theme JS lives loose in `assets/` referenced only by Liquid, which fallow can't trace.
- Hooks: `lefthook.yml`, `lefthook.yaml`, or `.lefthook.yml`
- Claude Code Action: `.github/workflows/*` containing `anthropics/claude-code-action`
- Shopify Lighthouse CI: `.github/workflows/*` containing `shopify/lighthouse-ci-action`
- Theme env config: `shopify.theme.toml` with `[environments.<name>]` sections — note a committed `password = "shptka_…"`, which is a leaked secret to migrate (see Theme Access & Ignore Files)
- Ignore file: `.shopifyignore` at the theme root

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
- `fallow` (dead-code scanner) **only when a `src/` directory of bundled JS source exists** — see Fallow (Dead Code). Skip it entirely for loose-`assets/` themes with no `src/`.

Commands after resolving versions:

```bash
# Bun default
bun add -d --exact @shopify/cli@<version> @biomejs/biome@<version> lefthook@<version> @playwright/test@<version> @axe-core/playwright@<version>

# Existing pnpm repo
pnpm add -D --save-exact @shopify/cli@<version> @biomejs/biome@<version> lefthook@<version> @playwright/test@<version> @axe-core/playwright@<version>
```

Add `vite`, `typescript`, `vitest`, and `fallow` only when detected or requested. Install `fallow` (`bun add -d fallow` / `pnpm add -D fallow`) only when `src/` exists.

After adding Playwright, install Chromium for local and CI runs:

```bash
bunx playwright install chromium
# pnpm repo:
pnpm exec playwright install chromium
```

## Files To Write

Copy these resources from this skill into the target repo when missing:

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
- `biome.json` from `resources/biome.shopify.json` when Biome has no config (see Biome Configuration — never clobber an existing `biome.json`/`biome.jsonc`)
- `.fallowrc.jsonc` from `resources/fallow.shopify.jsonc` **only when `src/` exists and fallow has no config** (see Fallow (Dead Code))
- `.shopifyignore` from `resources/shopifyignore.default` when missing (see Theme Access & Ignore Files — never clobber an existing one)
- `.env.example` from `resources/env.shopify.example` when missing (see Theme Access & Ignore Files)

Append `resources/agent-instructions.snippet.md` to existing root `AGENTS.md`, `CLAUDE.md`, and `.cursor/rules/*.mdc`. The snippet is bounded by `<!-- shopify-baseline:run-silent -->` … `<!-- /shopify-baseline:run-silent -->` sentinels: if both markers already exist, **replace exactly the text between them** (inclusive) so an upgrade learns the `bash scripts/check.sh` entry point without duplicating the body or deleting unrelated instructions after it; otherwise append the whole snippet. Older installs may have only the opening marker (no closing one) — in that case treat the open marker through end-of-block as the range and rewrite it with the bounded version. Key the idempotency skip on a `scripts/check.sh` mention, not merely `run_silent.sh` — older installs reference `run_silent.sh` but call the tools manually and would otherwise never pick up the new entry point. Do not create agent instruction files from scratch unless the user asks.

Add to `.gitignore` if not already ignored: `test-results/` (Playwright/axe artifacts), the QA artifact subdirectories `/qa/screenshots/` and `/qa/reports/`, and `.env` plus `.env.*` with a `!.env.example` exception — the secrets file must never be committed, but the example scaffold must stay tracked. **Git applies the last matching pattern, so `!.env.example` must come after every `.env`/`.env.*` line.** If the file already has a `!.env.example` exception, re-append it after any new env ignore patterns (or keep the env rules as one ordered block ending in the negation), otherwise the appended `.env.*` re-ignores the example. Ignore the concrete QA subdirectories rather than the whole `qa/` tree, so a repo that source-controls QA automation under `qa/` keeps those files tracked. Append only; never rewrite unrelated existing entries.

Resource templates default to Bun. In pnpm repos, rewrite `bun install`, `bun run`, and `bunx` to the pnpm equivalents before writing the file. For GitHub Actions workflows, also replace the Bun setup step with pnpm setup before the install step, for example `pnpm/action-setup` followed by `actions/setup-node` with `cache: pnpm`, so rewritten `pnpm install --frozen-lockfile` commands exist on a clean runner.

## Theme Access & Ignore Files

These steps apply when `shopify.theme.toml` exists (or the repo otherwise uses the Shopify CLI). They wire up non-interactive auth safely and keep the CLI from syncing the wrong files.

### Theme Access token in `.env`

Theme commands authenticate interactively (collaborator/OAuth) or with a **Theme Access password** (`shptka_…`, from the Theme Access app). The password is the path for CI and scripted runs. The CLI reads it from the `SHOPIFY_CLI_THEME_TOKEN` environment variable (the `--password` flag's env form).

- **Never commit the token.** If `shopify.theme.toml` (or any committed file) contains a literal `password = "shptka_…"`, treat it as a leaked secret: move the value into `.env`, delete the `password` line from the toml, and tell the user to **rotate it** in the Theme Access app — it's already in git history. Keep `store` and `theme` in the toml; only the secret moves out.
- **Before writing any token, confirm `.env` is untracked.** Adding `.gitignore` patterns doesn't untrack an already-committed file, so writing the token into a tracked `.env` would re-commit the secret. If `git ls-files --error-unmatch .env` succeeds (it's tracked), run `git rm --cached .env` first and warn the user to rotate anything already in history.
- **One environment (or all environments share a store/token):** write `SHOPIFY_CLI_THEME_TOKEN=shptka_…` to `.env`. The CLI uses it for every environment.
- **Multiple environments with distinct stores/tokens:** do **not** collapse them into one process-wide `SHOPIFY_CLI_THEME_TOKEN` — that authenticates every store with the same token, and `shopify theme push -e staging -e production` would then misauth or skip an environment. Store each environment's token under its own key (e.g. `SHOPIFY_CLI_THEME_TOKEN_STAGING`, `…_PRODUCTION`) in `.env`, and select per command with `shopify theme push -e staging --password "$SHOPIFY_CLI_THEME_TOKEN_STAGING"` (or a small wrapper that exports the matching token before each run).
- **Never invent a token.** If none exists, write only `.env.example` and tell the user to create one in the Theme Access app and drop it into `.env`.
- Write `.env.example` from `resources/env.shopify.example` so the variable is documented for the next contributor.
- Ensure `.gitignore` ignores `.env` / `.env.*` but keeps `!.env.example` (handled in Files To Write).
- **Loading:** the CLI does not auto-load `.env` for theme commands — it reads the live environment. Tell the user to load it via direnv (`.envrc` containing `dotenv`) or `set -a; source .env; set +a` before running `shopify` commands, and to set it as a masked secret in CI.

### `.shopifyignore`

`.shopifyignore` at the theme root tells `shopify theme push`/`pull` which files to skip. Patterns are bare paths, `*` wildcards, or `/regex/`. When the repo root is also the theme root, defensively exclude repo tooling and source (`node_modules/`, `src/`, `scripts/`, `.github/`, lockfiles, configs) so the CLI can't push them to the live theme or disturb them on pull — Shopify's docs recommend listing any repo files you don't want the CLI to interact with. The shipped default does this; reconcile the paths to the repo's actual layout.

- Write `resources/shopifyignore.default` to `.shopifyignore` when missing. Defaults: `assets/*.map` (sourcemaps shouldn't ship) and `*.DS_Store`.
- **`.shopifyignore` is bidirectional — it blocks both push and pull.** Do **not** default-ignore `config/settings_data.json`: it would also block *pulling* the live store's customizer settings (e.g. the `shopify-theme-pull` workflow's `pull --only config/settings_data.json`). To stop a push from clobbering merchant settings, pass `--ignore config/settings_data.json` on the push command instead.
- **Don't clobber an existing `.shopifyignore`.** Reconcile toward these defaults and report what changed rather than overwriting. Leave `config/settings_schema.json` and `locales/*.json` tracked — those are theme code.

## Package Scripts

Patch `package.json` with scripts that match installed tools. Preserve existing project scripts unless replacing an old equivalent.

Default script shape:

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

The granular `check:*` bodies stay direct tool commands — `biome check .`, `tsc --noEmit`, etc. resolve through `node_modules/.bin` whether the leaf runs under pnpm or Bun, so they need no `pnpm run`/`bun run` wrapper (wrapping makes the package manager look for a *script* of that name, e.g. `pnpm run biome check .` fails). Reach for `pnpm exec`/`bunx` only where a binary genuinely needs a package-manager wrapper. Do not use npm or yarn as the package-manager fallback.

`check` runs through `scripts/check.sh`, which sources `run_silent.sh` and wraps every `check:*` so a clean run is one line per check and only failures print output (the full failure log, so the agent has everything to diagnose; set `VERBOSE=1` to stream raw output live). A check that opts out — `check:a11y` with no preview URL, `check:dead-code` with no `src/` — echoes `skipped: …` and exits 0; `run_silent` renders that as a distinct `⊘ skipped` status so an unrun scan is never mistaken for a green pass. This is the entry point agents and local dev should call — never the raw `&&` chain, which floods context on every run. (CI runs the `check:*` steps discretely so each tool gets its own status and isolated failure log; GitHub already collapses clean step output, so the backpressure wrapper buys nothing there.) `check.sh` auto-detects pnpm vs Bun from `pnpm-lock.yaml`, so it needs no substitution.

## Biome Configuration

Biome owns JS/TS and the repo's own JSON config (`package.json`, `tsconfig.json`, `biome.json`); **Theme Check owns Liquid and Shopify-managed theme JSON**. The two must not fight.

- **Strict as the repo tolerates.** Start from `recommended: true`, promote warnings to errors, and enable additional `correctness`/`suspicious`/`style` rules. The shipped `resources/biome.shopify.json` already turns on a strict set (no unused imports/vars, no explicit `any`, `useConst`, `noNonNullAssertion`, etc.); ratchet further when the codebase is clean enough. Do **not** enable any rule that reorders or reformats Shopify-managed JSON.
- **Never lint or format the Shopify-managed theme directories.** Biome must stay out of `config/`, `locales/`, `layout/`, `sections/`, `snippets/`, `blocks/`, and `templates/`. Theme Check and the Shopify CLI manage the schema, settings, section groups, and locale files there; Biome's JSON formatter and key/import sorting would reorder them and contradict Theme Check. This scoping lives in two places, keep both in sync:
  - `biome.json` `files.includes` negations (so every `biome check .` invocation respects it).
  - the lefthook `biome-check` `exclude` globs (so staged-file `--write` runs never touch theme files).
- **Do lint `assets/`.** Many themes keep hand-written JS/CSS in `assets/`, so Biome covers it. Exclude only generated output — sourcemaps (`*.map`) and minified bundles (`*.min.js`, `*.min.css`) are already ignored. When the repo builds with Vite (or another bundler) into `assets/`, add that build's actual output files to the `files.includes` negations (and `.gitignore`) so Biome doesn't lint generated code — e.g. the `entryFileNames`/`chunkFileNames` the Vite config emits.
- **`assist.actions.source.useSortedKeys` stays `off`** — sorting keys would churn theme and locale JSON; only `organizeImports` (JS/TS) is on.
- **Don't clobber an existing `biome.json`/`biome.jsonc`.** If one exists, reconcile it toward this strictness and the theme-directory exclusions, and report what changed rather than overwriting.

`check:biome` stays `biome check .` — the config does the scoping, so there's a single source of truth and no per-call globs to remember.

## Fallow (Dead Code)

Fallow finds dead code by building a module graph from entry points. Shopify themes wire JS through Liquid (`{{ 'x.js' | asset_url | script_tag }}`), which fallow can't parse — so it only helps when the theme has a real bundled source tree.

- **Gate on `src/`.** Install and configure fallow **only when a `src/` directory of bundled JS source exists** (the kind Vite compiles into `assets/`). For loose-`assets/` themes with no `src/`, skip fallow entirely — every file would look unreachable (false positives), and theme scripts are usually side-effect IIFEs with no exports to analyze.
- **Scope to public `src/` roots; never `assets/` or `dist/`.** `assets/` is build output or Liquid-referenced scripts with no import graph; `dist/` is generated. The shipped `resources/fallow.shopify.jsonc` starts from common bundler entry files (`src/theme.*`, `src/index.*`, `src/main.*`, `src/app.*`) and ignores `assets/`, `dist/`, and the Shopify-managed theme directories. If the repo uses different build entries, reconcile Fallow's `entry` list to those files before enabling it.
- **Runs pre-push and in CI, not on commit** — fallow has no staged-file mode. The `check:dead-code` script self-skips unless `src/` and a fallow config both exist, so it's safe to wire unconditionally.
- **Don't clobber an existing fallow config.** If one exists, leave it; reconcile toward the `src/`-only scoping and report rather than overwriting.
- The Shopify-shaped question fallow does **not** answer — "which `assets/*.js` is no longer referenced by any Liquid template" — needs a Liquid-aware grep, not fallow. Out of scope here.

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
- On a violation, the spec writes full axe JSON into the `SHOPIFY_A11Y_OUT_DIR` *directory* (default `test-results/a11y/`, one `<index>-<page>.json` per scanned path) and fails with a compact summary (counts by impact + top rules + artifact path). The agent reads a file only when it needs node-level detail — keeping a noisy a11y run from flooding context. `SHOPIFY_A11Y_OUT_DIR` must be a directory, not a file path.

Do not add ESLint only for accessibility if the repo is Biome-first and mostly Liquid. Do not add WAVE to the default baseline; WAVE's API path needs API credits or a licensed stand-alone engine, so it belongs in a separate paid/enterprise workflow. Consider `pa11y-ci` or `html-validate` only as optional extensions when the user asks for deeper URL/sitemap or rendered-HTML validation.

If a preview URL is available, use the browser to inventory important pages before finalizing `SHOPIFY_A11Y_PATHS`. Do not consider the accessibility baseline complete until it covers at least homepage, one collection page, and one product page. Then propose any obvious high-traffic footer links, search, cart, account, and landing pages surfaced in navigation before hardcoding the path list in repo config.

## GitHub Actions

Create or update three separate workflow surfaces:

1. `ci.yml`
   - Runs static checks on every PR and pushes to the default branch.
   - Uses `shopify/theme-check-action@v2` for GitHub Actions Theme Check instead of running the local `check:theme` package script.
   - Pass `theme_root: .` and a pinned `version` matching the resolved `@shopify/cli` version so CI does not float to the newest Theme Check runtime.
   - Set up a Node version compatible with the pinned Shopify CLI before running Theme Check. For example, Shopify CLI `4.1.0` requires Node `>=22.12.0`, so the template uses Node `24`.
   - Do not pass `token` or `base` in the default template. Without `token`, the action exits with the Theme Check status, so the main CI job fails on Liquid/theme errors and default-branch pushes scan the full theme.
   - Optional PR annotation mode may pass `token: ${{ github.token }}` and `base: __DEFAULT_BRANCH__`, but only on pull request events. Add `permissions: contents: read, checks: write`, and ensure branch protection requires the generated `Theme Check Report` check because token mode creates annotations in a separate check run.
   - When upgrading an existing workflow, preserve custom `shopify theme check` flags such as `--fail-level` or custom config paths by moving them to the action's `flags` input.
   - When upgrading existing workflows, remove duplicate GitHub Actions Theme Check steps. This includes `shopify theme check`, package-manager `check:theme` commands, and older `theme-check-action` variants.
   - Keep local package scripts and lefthook commands; only dedupe the GitHub Actions workflow surface.
   - Replace the `__DEFAULT_BRANCH__` placeholder with the detected default branch before writing the workflow.
   - Runs Playwright axe only when `SHOPIFY_PREVIEW_URL` is available.
   - Runs Vitest only when configured.
   - Pin GitHub Actions to full commit SHAs after resolving the current latest tag or release. Resource templates include pinned refs as of June 15, 2026; refresh them when installing later.

2. `shopify-lighthouse-ci.yml`
   - Uses `shopify/lighthouse-ci-action@v1`.
   - Optional but recommended when the repo has a benchmark store.
   - Requires benchmark store secrets: `SHOP_STORE`, `SHOP_CLIENT_ID`, `SHOP_CLIENT_SECRET`.
   - If those required secrets are absent, the workflow must skip cleanly instead of failing.
   - Replace the `__DEFAULT_BRANCH__` placeholder with the detected default branch before writing the workflow.
   - Runs homepage plus product and collection pages; set `SHOPIFY_LIGHTHOUSE_PRODUCT_HANDLE` and `SHOPIFY_LIGHTHOUSE_COLLECTION_HANDLE` repository variables for stable representative pages, otherwise the action defaults to the first product/collection.
   - Keep initial thresholds realistic, then raise after the repo is clean.

### Shopify Lighthouse Credentials

Gathering the benchmark-store secrets (`SHOP_STORE`, `SHOP_CLIENT_ID`, `SHOP_CLIENT_SECRET`) needs a supervised Dev Dashboard browser session and careful secret handling. See `references/lighthouse-credentials.md` for the full walkthrough; only read it when actually wiring up Lighthouse CI.

3. `claude-code-review.yml`
   - Uses `anthropics/claude-code-action@v1`.
   - Use Claude Code subscription auth with `claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}`.
   - Requires repository secret `CLAUDE_CODE_OAUTH_TOKEN`.
   - Keep `permissions.id-token: write`; this workflow does not pass a `github_token`, so Claude Code Action uses the default GitHub App OIDC auth path.
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
- Biome config and scripts — strictness plus theme-directory exclusions so it doesn't fight Theme Check (see Biome Configuration)
- Fallow dead-code config and scripts when `src/` exists — scoped to `src/`, never `assets/`/`dist/` (see Fallow (Dead Code))
- Vite build path and asset output safety
- Playwright/axe coverage and `SHOPIFY_A11Y_PATHS`
- optional Vitest presence where complex JS exists
- lefthook local gates
- GitHub Actions CI, Theme Check Action deduping, Lighthouse CI, action SHA pinning, and Claude Code v1 usage
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
  - Fallow dead-code if `src/` and a fallow config exist
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
