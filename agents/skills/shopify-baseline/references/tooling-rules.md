# Tooling Rules

Use this when configuring Biome, Fallow, Vite, and accessibility coverage.

## Biome

Biome owns JS/TS and repo-owned JSON such as `package.json`, `tsconfig.json`, and `biome.json`. Theme Check owns Liquid and Shopify-managed theme JSON.

- Start from `recommended: true`, promote warnings to errors, and enable strict correctness/suspicious/style rules as tolerated.
- The bundled `resources/biome.shopify.json` already includes a strict set such as unused imports/vars, no explicit `any`, `useConst`, and no non-null assertions.
- Never lint or format Shopify-managed directories: `config/`, `locales/`, `layout/`, `sections/`, `snippets/`, `blocks/`, and `templates/`.
- Keep Biome scoping in both `biome.json` `files.includes` negations and lefthook `biome-check` exclude globs.
- Do lint `assets/` because many themes keep hand-written JS/CSS there.
- Exclude generated sourcemaps, minified bundles, and actual Vite output files.
- Keep `assist.actions.source.useSortedKeys` off.
- If an existing `biome.json` or `biome.jsonc` exists, reconcile toward strictness and theme-directory exclusions; do not clobber.

`check:biome` stays `biome check .`; the config is the single source of truth.

## Fallow

Fallow helps only when the theme has a bundled source tree.

- Install/configure fallow only when `src/` contains bundled JS/TS source.
- Skip entirely for loose `assets/` themes with no `src/`.
- Scope to public `src/` roots; never `assets/` or `dist/`.
- Reconcile entry points to the repo's actual build entries.
- Run pre-push and CI, not pre-commit.
- Invoke as `fallow dead-code --quiet --fail-on-issues`: without `--fail-on-issues`, warn-level findings exit 0 and the gate silently passes; `--quiet` drops stderr progress noise from captured output.
- Do not clobber existing fallow config.

Fallow does not answer "which `assets/*.js` is no longer referenced by Liquid"; that needs Liquid-aware grep and is out of scope.

## Vite Conversion

When old frontend build tooling exists, propose Vite migration but do not perform it without explicit confirmation.

The proposal must include:

- detected current build tool
- source entry points
- expected output files in `assets/`
- Liquid asset references that may need to change
- validation commands that prove the migration

Rules:

- Preserve current source entry names where possible.
- Output compiled assets into Shopify `assets/`.
- Set `emptyOutDir: false`.
- Keep filenames stable if Liquid references them directly.
- Do not rewrite Liquid asset references unless filenames change.
- Keep config small and add plugins only when the repo already needs them.

Use `resources/vite.config.shopify.ts` as the starting template after confirmation.

## Accessibility

Default gate: Playwright plus `@axe-core/playwright`.

- Scan rendered pages from `BASE_URL`.
- Use WCAG A/AA tags: `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, `wcag22aa` when supported.
- Cover home, collection, product, cart, search, mobile navigation, drawer/modal states when URLs/selectors are known.
- Configure `SHOPIFY_A11Y_PATHS` as a comma-separated path list.
- On violation, write full axe JSON under `SHOPIFY_A11Y_OUT_DIR`, default `test-results/a11y/`, and fail with a compact summary.
- The output variable is a directory, not a file path.

Do not add ESLint only for accessibility in a Biome-first, mostly Liquid repo. Do not add WAVE by default; it belongs in a paid/enterprise workflow. Consider pa11y-ci or html-validate only when the user asks for deeper rendered-HTML validation.

If a preview URL is available, use the browser to inventory important pages before finalizing paths. Baseline coverage should include at least homepage, one collection, and one product page, then propose any obvious footer, search, cart, account, or landing pages before hardcoding them.
