# <Store name> theme

## Why it exists

<!-- The store, who shops it, and what this theme is for. Plain language, one short paragraph. Add a status line if the repo shows one. -->

## Principles

<!-- Three to five outcomes the theme is judged by, such as conversion, page speed, accessibility, and merchant editing in the theme editor. Outcomes, not code style. -->

## How it fits together

<!-- Theme base and version, where custom source lives and how it builds into assets/, apps that inject markup, and the environments in shopify.theme.toml. Link detailed docs instead of restating them. -->

<!-- shopify-baseline:run-silent -->
## Working here

| Command | Use |
|---|---|
| `bash scripts/check.sh` | Every check, one line each; failures print full output |
| `<pm> run check:theme` | Theme Check |
| `<pm> run check:biome` | Biome on JS, TS, and repo JSON |
| `<pm> run check:a11y` | Playwright axe; needs `BASE_URL` or `SHOPIFY_PREVIEW_URL` |

Don't start `shopify theme dev` or Vite unless asked. Browser checks use an already-running preview URL.
<!-- /shopify-baseline:run-silent -->

## Docs

<!-- One line per doc worth reading, with what it covers. -->
