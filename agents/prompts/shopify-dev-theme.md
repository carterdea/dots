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

5. Handle theme limit reached
- If the push fails because the store has hit its theme limit (20 for most plans, 100 for Plus):
  a. Run `shopify theme list` to get all themes
  b. Parse the output to identify each theme's name, ID, and role
  c. Present a list of deletion candidates to the user, sorted by preference:
     - Prefer themes prefixed with `[DEV]` (most disposable)
     - Then other unpublished/draft themes
     - **NEVER** suggest deleting the published (live) theme
  d. Ask the user which theme(s) to delete
  e. After confirmation, delete the selected theme(s):
     ```bash
     shopify theme delete --theme <THEME_ID> --force
     ```
  f. Retry the push from step 4

6. Report the theme preview URL and editor URL
- Always include the base theme preview URL
- Additionally, infer relevant page-specific preview URLs from conversation context:
  - Look at which template files were edited during the session (e.g., `templates/product.json`, `sections/collection-*.liquid`, `templates/page.contact.json`)
  - Map templates to storefront paths:
    - `templates/product.*` → `/products/{any-product-handle}`
    - `templates/collection.*` → `/collections/{any-collection-handle}`
    - `templates/page.*` → `/pages/{any-page-handle}`
    - `templates/index.*` → `/`
    - `templates/cart.*` → `/cart`
    - `templates/search.*` → `/search`
    - `templates/blog.*` → `/blogs/{any-blog-handle}`
    - `templates/article.*` → `/blogs/{blog-handle}/{article-handle}`
  - Append these paths to the theme preview URL so the user can jump directly to the relevant pages
  - If specific handles were mentioned in conversation (from `/qa`, `/handoff`, or general discussion), use those; otherwise use a placeholder and note the user should swap in a real handle
- Example output:
  ```
  Preview:  https://{store}.myshopify.com/?preview_theme_id=123456
  Product:  https://{store}.myshopify.com/products/example-product?preview_theme_id=123456
  Editor:   https://admin.shopify.com/store/{store}/themes/123456/editor
  ```

## Usage

```
/shopify-dev-theme
```
