<!-- shopify-baseline:run-silent -->

## Shopify Baseline Checks

Run `bash scripts/check.sh` for verification. It wraps every check in `scripts/run_silent.sh`, so a clean run is one line per check and only failures print output (the full failure log). Set `VERBOSE=1` to stream raw output live.

Do not start `shopify theme dev`, Vite dev servers, or other long-running dev commands unless the user explicitly asks. Browser checks should use an already-running URL via `BASE_URL` or `SHOPIFY_PREVIEW_URL`.
