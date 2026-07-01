# Shopify Lighthouse Credentials

Read this when setting up `shopify-lighthouse-ci.yml` and the benchmark-store secrets it needs (`SHOP_STORE`, `SHOP_CLIENT_ID`, `SHOP_CLIENT_SECRET`).

These credentials need an authenticated Shopify Dev Dashboard session. The app is created in the user's Shopify organization in Dev Dashboard, not inside an individual theme repo. Then it is installed on the selected benchmark store, which can be a dev store, client transfer store, or merchant-owned collaboration store if the organization has access.

Prefer a supervised headed-browser setup for this API-only Lighthouse app: open the browser, let the user log in and complete 2FA, then automate the setup steps with the user's explicit approval.

1. Open `https://dev.shopify.com/dashboard` in a headed browser.
2. Ask the user to log in and complete any 2FA, organization selection, store selection, collaborator approval, or app install approval.
3. Create a Dev Dashboard app for the benchmark store.
4. Create/release a version with:
   - app URL `https://shopify.dev/apps/default-app-home`
   - the newest stable Webhooks API version offered by the UI
   - scopes `read_products` and `write_themes`
5. Install the app on the benchmark store and approve the scopes.
6. Open the app Settings page and gather the Client ID and Client secret.

Shopify CLI note:

- Shopify CLI can create app projects and app records in the Dev Dashboard, for example with `shopify app init --name <name> --organization-id <org-id> --template <template>`.
- Do not use CLI app scaffolding as the default Lighthouse credential path for theme repos. It creates a conventional app project and is heavier than needed for an API-only benchmark-store integration.
- If the user specifically wants CLI-managed app configuration, create it outside the theme repo or in a clearly named separate app directory, then link/deploy app configuration intentionally. Still expect user auth/approval for the target store and secret handling.

Automate the repo-side setup after those values are known:

```bash
# Non-secret values are fine inline.
gh secret set SHOP_STORE --body "<store>.myshopify.com"
gh secret set SHOP_CLIENT_ID --body "<client-id>"
# Secrets: omit --body so gh reads the value from stdin/prompt, never argv (which
# leaks into shell history and process listings). Paste when prompted, or pipe:
gh secret set SHOP_CLIENT_SECRET          # or: pbpaste | gh secret set SHOP_CLIENT_SECRET
# Only when the benchmark store is password protected:
gh secret set SHOP_PASSWORD               # paste when prompted
```

Secret-handling rule:

- Do not print the Client secret in chat, logs, PRs, or files.
- Prefer piping from the clipboard or a hidden prompt directly into `gh secret set`.
- If the browser reveals the secret to the agent, immediately store it as `SHOP_CLIENT_SECRET`, avoid repeating it, and clear any temporary notes/clipboard when practical.

Useful commands for secret capture:

```bash
# After the user copies the Client secret from the browser:
pbpaste | gh secret set SHOP_CLIENT_SECRET

# For non-secret values the agent may set directly:
gh secret set SHOP_STORE --body "<store>.myshopify.com"
gh secret set SHOP_CLIENT_ID --body "<client-id>"
```

The skill can infer or help gather:

- `SHOP_STORE` from `shopify.theme.toml`, existing deploy workflows, or the user's supplied store domain.
- `SHOPIFY_LIGHTHOUSE_PRODUCT_HANDLE` and `SHOPIFY_LIGHTHOUSE_COLLECTION_HANDLE` by browsing the preview/store and choosing representative stable pages. These are repository variables, not secrets:

```bash
gh variable set SHOPIFY_LIGHTHOUSE_PRODUCT_HANDLE --body "<product-handle>"
gh variable set SHOPIFY_LIGHTHOUSE_COLLECTION_HANDLE --body "<collection-handle>"
```

The skill cannot safely automate:

- Login, 2FA, organization selection, or any approval screen that requires the user's credentials or judgment.
- Secret handling that would require printing the Client secret into conversation history.
