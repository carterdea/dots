# Shopify Dev Theme

Create an unpublished Shopify theme named after the current git branch.

## Steps

1. Check for `shopify.theme.toml`
- Look for `shopify.theme.toml` in the current directory
- If it does NOT exist, warn the user: "No `shopify.theme.toml` found in this directory. Are you sure you want to continue?"
- Wait for confirmation before proceeding

2. Get branch name
```bash
git branch --show-current
```

3. Determine theme name
- If on `main` (or `master`): do NOT auto-create a theme. Ask the user what they want to name this dev theme. Wait for their answer.
- Otherwise, humanize the branch name:
  - Remove prefix (e.g., `fix/`, `feature/`, `feat/`)
  - Convert hyphens to spaces
  - Title case each word
  - Prefix with `[DEV]`

Example: `fix/search-featured-product-styling` → `[DEV] Search Featured Product Styling`

4. Push full theme
```bash
shopify theme push --theme "[DEV] Theme Name"
```
- This pushes all theme files, not just changed files
- Creates the theme if it doesn't exist, updates if it does

5. Report the theme preview URL and editor URL

## Usage

```
/shopify-dev-theme
```
