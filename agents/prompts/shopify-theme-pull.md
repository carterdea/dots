# Shopify Theme Pull

Pull merchant-edited content (settings and templates) from a live Shopify theme.

## Steps

1. Check for `shopify.theme.toml`
- Look for `shopify.theme.toml` in the current directory
- If it does NOT exist, warn the user: "No `shopify.theme.toml` found in this directory. Are you sure you want to continue?"
- Wait for confirmation before proceeding

2. Identify the target theme
```bash
shopify theme list
```
- Default to the **live** (published) theme
- Show the user which theme will be pulled from and ask for confirmation
- If the user wants a different theme, let them pick from the list

3. Pull only settings and templates
```bash
shopify theme pull --theme THEME_ID --only config/settings_data.json --only "templates/*"
```

4. Show what changed
```bash
git diff --stat
```
- Display the diff summary so the user can see exactly what the merchant changed
- If no changes, report "No differences from local files"

5. Offer to commit
- Ask the user if they want to commit the pulled changes
- If yes, stage only the pulled files and commit with message: "Pull merchant content from live theme"
- If no, leave changes unstaged for manual review

## Usage

```
/shopify-theme-pull
```
