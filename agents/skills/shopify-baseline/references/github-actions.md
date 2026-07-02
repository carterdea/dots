# GitHub Actions Reference

Use this when creating or upgrading Shopify baseline workflows.

## CI

Create or update `.github/workflows/ci.yml`.

- Runs static checks on every PR and pushes to the default branch.
- Uses `shopify/theme-check-action@v2` instead of running local `check:theme`.
- Pass `theme_root: .` and a pinned `version` matching the resolved `@shopify/cli` version.
- Set up a Node version compatible with the pinned Shopify CLI.
- Default template should not pass `token` or `base`; without token, the main CI job fails on Theme Check errors.
- Optional PR annotation mode may pass `token: ${{ github.token }}` and `base: __DEFAULT_BRANCH__` only on pull requests. Add `permissions: contents: read, checks: write` and require the generated `Theme Check Report` check in branch protection.
- Preserve custom `shopify theme check` flags by moving them to the action `flags` input.
- Remove duplicate GitHub Actions Theme Check steps, including raw `shopify theme check`, package `check:theme`, and older action variants.
- Keep local package scripts and lefthook commands.
- Replace `__DEFAULT_BRANCH__`.
- Run Playwright axe only when `SHOPIFY_PREVIEW_URL` is available.
- Run Vitest only when configured.
- Pin GitHub Actions to full commit SHAs after resolving current latest tags/releases. Refresh bundled refs when installing after their recorded date.

## Shopify Lighthouse CI

Create `.github/workflows/shopify-lighthouse-ci.yml` when the repo has a benchmark store or the user wants the template.

- Uses `shopify/lighthouse-ci-action@v1`.
- Requires `SHOP_STORE`, `SHOP_CLIENT_ID`, and `SHOP_CLIENT_SECRET`.
- If required secrets are absent, skip cleanly instead of failing.
- Replace `__DEFAULT_BRANCH__`.
- Runs homepage plus product and collection pages.
- Use repository variables `SHOPIFY_LIGHTHOUSE_PRODUCT_HANDLE` and `SHOPIFY_LIGHTHOUSE_COLLECTION_HANDLE` for stable representative pages when available.
- Keep initial thresholds realistic; raise them after the repo is clean.

Gathering benchmark-store secrets requires supervised Dev Dashboard browser work. Read [`lighthouse-credentials.md`](lighthouse-credentials.md) only when actually wiring up Lighthouse credentials.

## Claude Code Review

Create or upgrade `.github/workflows/claude-code-review.yml`.

- Uses `anthropics/claude-code-action@v1`.
- Uses subscription auth with `claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}`.
- Requires repository secret `CLAUDE_CODE_OAUTH_TOKEN`.
- Keep `permissions.id-token: write`.
- Use `prompt` for review instructions.
- Use `claude_args: --append-system-prompt ...` for extra behavioral framing.

Upgrade old beta workflows:

- `@beta` -> `@v1`
- remove `mode`
- `direct_prompt` / `override_prompt` -> `prompt`
- `custom_instructions` -> `claude_args: --append-system-prompt`
- `model`, `max_turns`, `allowed_tools`, `disallowed_tools` -> `claude_args`

The review prompt should ask for normal code review plus Shopify theme best practices and accessibility issues. Do not include private client risk rationale.

## Upgrade Existing Baselines

Compare current setup against baseline criteria and propose the smallest improvements:

- package manager and installed versions
- Theme Check config/scripts/action
- Biome strictness and Shopify directory exclusions
- Fallow only when `src/` exists, scoped to `src/`
- Vite output path and asset safety
- Playwright axe coverage and `SHOPIFY_A11Y_PATHS`
- Vitest where complex JS exists
- lefthook gates
- CI, Theme Check Action dedupe, Lighthouse CI, action SHA pinning, Claude Code v1
- `scripts/run_silent.sh` and agent-instruction discoverability

Report proposed changes first. Patch only after confirmation for risky migrations, especially build-tool conversions.
