---
name: shopify-theme-pull
description: Pull merchant-edited content from a live Shopify theme
user-invocable: true
disable-model-invocation: true
---

# Shopify Theme Pull

Pull merchant-edited content (settings and templates) from a live Shopify theme.

## Steps

1. Check for `shopify.theme.toml`
- If it does NOT exist, warn the user
- Wait for confirmation before proceeding

2. Identify the target theme
shopify theme list
- Default to the **live** (published) theme
- Show the user which theme will be pulled from and ask for confirmation

3. Pull only settings and templates
shopify theme pull --theme THEME_ID --only config/settings_data.json --only "templates/*"

4. Show what changed
git diff --stat

5. Offer to commit
- If yes, stage only the pulled files and commit
- If no, leave changes unstaged for manual review

## Usage

/shopify-theme-pull
