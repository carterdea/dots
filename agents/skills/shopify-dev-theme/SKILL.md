---
name: shopify-dev-theme
description: Create an unpublished Shopify theme named after the current git branch
user-invocable: true
---

# Shopify Dev Theme

Create an unpublished Shopify theme named after the current git branch.

## Steps

1. Check for `shopify.theme.toml`
- Look for `shopify.theme.toml` in the current directory
- If it does NOT exist, warn the user and wait for confirmation before proceeding

2. Determine the `--environment` flag
- Parse all `[environments.<name>]` sections from `shopify.theme.toml`
- If there is **one environment**: use it automatically (e.g. `--environment development`)
- If there are **multiple environments**: list them and ask the user which one to use; wait for their answer

3. Get branch name
```
git branch --show-current
```

4. Determine theme name
- If on `main` (or `master`): do NOT auto-create a theme. Ask the user what they want to name this dev theme. Wait for their answer.
- Otherwise, humanize the branch name:
  - Remove prefix (e.g., `fix/`, `feature/`, `feat/`)
  - Convert hyphens to spaces
  - Title case each word
  - Prefix with `[DEV]`

Example: `fix/search-featured-product-styling` -> `[DEV] Search Featured Product Styling`

5. Push full theme
```
shopify theme push --environment <env> --theme "[DEV] Theme Name"
```
- Creates the theme if it doesn't exist, updates if it does

6. Handle theme limit reached
- If the push fails because the store has hit its theme limit:
  a. Run `shopify theme list --environment <env>` to get all themes
  b. Present deletion candidates (prefer [DEV] themes, then unpublished; NEVER suggest the live theme)
  c. Ask the user which theme(s) to delete
  d. Delete selected theme(s) and retry push

7. Report the theme preview URL and editor URL
- Include base preview URL
- Infer page-specific preview URLs from conversation context (edited templates -> storefront paths)
- Include editor URL

## Usage

/shopify-dev-theme
