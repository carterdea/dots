# Shopify Dev Theme

Create an unpublished Shopify theme named after the current git branch.

## Steps

1. Get branch name
```bash
git branch --show-current
```

2. Humanize the branch name
- Remove prefix (e.g., `fix/`, `feature/`, `feat/`)
- Convert hyphens to spaces
- Title case each word
- Prefix with `[DEV]`

Example: `fix/search-featured-product-styling` → `[DEV] Search Featured Product Styling`

3. Push full theme
```bash
shopify theme push --theme "[DEV] Humanized Name"
```
- This pushes all theme files, not just changed files
- Creates the theme if it doesn't exist, updates if it does

4. Report the theme preview URL and editor URL

## Usage

```
/shopify-dev-theme
```
