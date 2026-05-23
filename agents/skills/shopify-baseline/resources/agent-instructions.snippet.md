<!-- shopify-baseline:run-silent -->

## Shopify Baseline Checks

Use `scripts/run_silent.sh` for agent-run verification so successful checks stay compact and failures include full output.

```bash
source scripts/run_silent.sh
run_silent "theme check" bun run check:theme
run_silent "biome" bun run check:biome
run_silent "typecheck" bun run check:type
run_silent "tests" bun run check:test
run_silent "accessibility" bun run check:a11y
```

Do not start `shopify theme dev`, Vite dev servers, or other long-running dev commands unless the user explicitly asks. Browser checks should use an already-running URL via `BASE_URL` or `SHOPIFY_PREVIEW_URL`.
