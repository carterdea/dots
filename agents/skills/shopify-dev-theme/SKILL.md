---
name: shopify-dev-theme
description: Create an unpublished Shopify theme named after the current git branch
user-invocable: true
disable-model-invocation: true
---

# Shopify Dev Theme

Create an unpublished Shopify theme named after the current git branch.

## Steps

1. Check for `shopify.theme.toml`
- Look for `shopify.theme.toml` in the current directory
- If it does NOT exist, warn the user
- Wait for confirmation before proceeding

2. Get branch name
git branch --show-current

3. Determine theme name
- If on `main` (or `master`): do NOT auto-create a theme. Ask the user what they want to name this dev theme. Wait for their answer.
- Otherwise, humanize the branch name:
  - Remove prefix (e.g., `fix/`, `feature/`, `feat/`)
  - Convert hyphens to spaces
  - Title case each word
  - Prefix with `[DEV]`

Example: `fix/search-featured-product-styling` -> `[DEV] Search Featured Product Styling`

4. Push full theme
shopify theme push --theme "[DEV] Theme Name"
- Creates the theme if it doesn't exist, updates if it does

5. Handle theme limit reached
- If the push fails because the store has hit its theme limit:
  a. Run `shopify theme list` to get all themes
  b. Present deletion candidates (prefer [DEV] themes, then unpublished; NEVER suggest the live theme)
  c. Ask the user which theme(s) to delete
  d. Delete selected theme(s) and retry push

6. Report the theme preview URL and editor URL
- Include base preview URL
- Infer page-specific preview URLs from conversation context (edited templates -> storefront paths)
- Include editor URL

## Usage

/shopify-dev-theme
