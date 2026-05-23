---
name: shopify-trello-delivery
description: Ship Shopify theme work from a Trello ticket end to end: inspect the card including Figma links, implement the theme change, deploy or update the correct preview/dev theme, browser-QA desktop and mobile against Figma when available, create or update the GitHub PR, attach screenshots, comment on Trello, and move the card forward. Use this whenever the user mentions a Shopify theme task with a Trello card, Figma design/artboard, preview theme, Customizer, dev theme, PR handoff, Ready for Review/Testing, or asks to update an existing Shopify PR from a ticket.
---

# Shopify Trello Delivery

## Purpose

Use this skill to keep Shopify/Trello delivery work complete rather than stopping at code. The goal is that the ticket, PR, preview theme, screenshots, and final status all agree about what changed and how it was verified.

## Dependencies

- `git` and GitHub CLI or connector access for branch, PR, and PR comment work.
- Shopify CLI with access to the relevant store from `shopify.theme.toml`.
- Trello CLI with authenticated access to the ticket board.
- Figma Desktop MCP when the Trello ticket or comments contain Figma design links.
- Browser automation for preview-theme QA and screenshots.

## Core Defaults

- Default to action. Do not ask unless a decision is truly blocking.
- Do not work on `main` or `master`. If there is no PR branch, create a branch before editing.
- Never use `git add .`; stage files explicitly.
- Do not run `shopify theme dev` or other dev servers unless asked.
- Prefer targeted checks: `git diff --check`, `shopify theme check`, relevant package scripts, and browser verification on the touched surface.
- For mobile/theme UI changes, verify with a mobile viewport in the browser before handing off.
- Use existing PRs and existing preview themes from the Trello card before creating new ones.
- Treat Figma links in Trello descriptions and comments as source material. Inspect the linked node/artboard before implementing design-sensitive work.
- Figma links in the Trello card description take precedence over Figma links in comments. Use comment links only when the description has no Figma link or a later comment explicitly supersedes the description design.
- After updating a Trello ticket, always include the Trello ticket URL in the final response.
- Ensure the GitHub PR description contains a link to the Trello ticket.
- Always capture desktop and mobile screenshots from the correct deployed preview theme before handoff.
- Upload those screenshots to both the GitHub PR and the Trello card. If the available GitHub tooling cannot attach images, use the browser/GitHub UI or a connector that can upload files; do not silently downgrade to text-only.
- If the task says "dev theme" and `shopify.theme.toml` has multiple environments, infer the environment instead of stopping:
  - If updating an existing preview theme, use the store/environment that owns that theme.
  - If the preview must be client-visible on the merchant store, use the production store as an unpublished dev theme.
  - If the command fails for access or theme not found, try the other configured environment before asking.
- If the store is at the theme limit, update an existing task-related theme if one exists. Only ask before deleting themes. Never suggest deleting the live theme.

## Workflow

1. Orient on the ticket and repo.
   - Run `git status --short --branch` and confirm the current branch/worktree state.
   - Read repo instructions: `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md` when present.
   - Check `shopify.theme.toml` early; it controls store and environment names.
   - Verify Trello auth with `trello auth status` before card operations.
   - Fetch the Trello card, comments, and attachments. Extract:
     - Linked PR.
     - Existing preview theme URL or `preview_theme_id`.
     - Existing Customizer URL.
     - Figma links in the description and all comments, especially URLs with `node-id=`.
     - Acceptance criteria and the latest client/QA comments.
   - Choose the primary Figma reference in this order:
     - Card description Figma links.
     - Comment Figma links that explicitly say they replace or supersede the description design.
     - Most recent relevant comment Figma link, only when the description has no Figma link.
   - For each relevant Figma link:
     - Decode the `node-id` from the URL (`701-56` becomes `701:56`) when passing it to Figma MCP.
     - Prefer `mcp__figma_desktop__get_design_context` with the task type and artifact type when available.
     - Use `mcp__figma_desktop__get_screenshot` to capture a reference image for QA.
     - Use `mcp__figma_desktop__get_metadata` only when you need to choose between nearby frames or understand hierarchy.
     - If Figma MCP is unavailable or cannot access the file, report that clearly and fall back to the ticket screenshots/comments instead of guessing.
   - Keep the selected Figma URL/node ID available for the PR body, PR screenshot comment, and Trello handoff when design matching is part of the task.

2. Choose the branch path.
   - Existing PR on the ticket:
     - Use `gh pr view <number> --json headRefName,baseRefName,url,state,title`.
     - Fetch and switch to the PR head branch.
   - No existing PR:
     - Start from the repo's correct base branch. Prefer the PR base convention if visible in repo docs, otherwise inspect default branch and Shopify deploy config.
     - Create a branch named from the ticket, for example `codex/<card-short-id>-<short-slug>`.
     - Keep the branch title human-readable enough to become a `[DEV]` theme name.

3. Implement narrowly.
   - Inspect the real theme section/template/assets before editing.
   - Adapt Figma measurements to the existing theme system rather than copying generated Figma code blindly.
   - Prefer existing theme classes, section settings, fonts, colors, spacing tokens, and responsive breakpoints over one-off CSS.
   - Keep generated Shopify JSON comments when they already exist.
   - For theme JSON files with Shopify generated headers, preserve the header unless the file is genuinely new.
   - Use `apply_patch` for manual edits.
   - Keep changes scoped to the ticket and avoid unrelated formatting churn.

4. Validate locally.
   - Run `git diff --check`.
   - Run `shopify theme check --path . --output json` when Shopify CLI is available.
   - If Theme Check reports existing repo-wide issues, filter the JSON for touched files and report that distinction.
   - Run relevant package checks if the touched files require it. Use the project package manager (`pnpm` if already used, otherwise `bun`).

5. Deploy or update the preview theme.
   - Existing preview theme on the Trello card or PR:
     - Push to that theme ID: `shopify theme push --environment <env> --theme <theme-id> --json`.
   - No existing preview theme:
     - Humanize the branch name into `[DEV] <Title Case Branch>`.
     - Create/update the unpublished theme: `shopify theme push --environment <env> --theme "[DEV] Name" --unpublished --json`.
   - If `--theme "[DEV] Name"` fails because the theme does not exist, retry with `--unpublished`.
   - If the theme limit is reached:
     - Run `shopify theme list --environment <env> --json`.
     - Prefer updating any task-related `[DEV]` theme if present.
     - Otherwise present deletion candidates and wait for explicit deletion approval.
   - Capture and keep the returned `preview_url`, `editor_url`, `theme.id`, and `theme.name`.
   - Infer page-specific preview URLs from touched templates or ticket context, for example `/pages/help-about-our-product?preview_theme_id=<id>#help-faqs`.
   - Build a Customizer URL using Shopify admin when the CLI editor URL is storefront-domain based:
     - `https://admin.shopify.com/store/<store-handle>/themes/<theme-id>/editor`
     - Add `previewPath=<encoded path>` when useful.

6. Browser QA the preview.
   - Open the page-specific preview URL.
   - For mobile issues, set a mobile viewport such as `430x932x3,mobile,touch`.
   - Also check a desktop viewport such as `1440x1000`.
   - Verify real DOM/CSS behavior, not just visual intuition.
   - When a Figma node was available, compare the preview against the Figma reference for the specific viewport(s) represented by the artboard.
   - If the Figma file has separate desktop and mobile frames, inspect/capture both and use them as the expected visual references.
   - For scroll or animation changes, exercise the interaction and inspect computed state.
   - If the deploy output omits `www` but the site uses `www`, test the canonical storefront URL that customers see.
   - Save two screenshot files with clear names:
     - `<slug>-desktop.png`
     - `<slug>-mobile.png`
   - The screenshots must be taken from the deployed preview theme URL, including `preview_theme_id=<id>` and any relevant path/hash.
   - If the task was Figma-backed, name the screenshots so it is clear they are implementation screenshots, not Figma references.

7. Commit, push, and PR.
   - Stage only touched files explicitly.
   - Commit in logical groups with concise messages.
   - Push the branch.
   - Existing PR:
     - Reuse it and report the URL.
     - Check the PR body. If it does not link to the Trello ticket, update the PR body to include the Trello URL.
   - No PR:
     - Create a PR after push. Use the Trello card title as the PR title unless repo conventions say otherwise.
     - PR body should include a short summary, checks, preview URL, Customizer URL, Trello link, and Figma link when one drove the implementation.
   - Upload the desktop and mobile screenshots to the PR:
     - Prefer a PR comment containing both images after the preview theme is deployed and verified.
     - If the GitHub CLI cannot attach images directly, use an available GitHub connector/browser upload path.
     - If image upload is blocked by tooling or auth, stop and report the blocker instead of pretending the screenshots were uploaded.
   - Do not use emojis in PR text.

8. Update Trello.
   - Add a card comment with exactly these prefixes:
     - `*PR:* <pr-url>`
     - `*Preview:* <page-preview-url>`
     - `*Customizer:* <customizer-url>`
     - `*Figma:* <figma-url>` when a Figma design was used.
   - Add one short paragraph explaining what changed and what was verified.
   - Attach the desktop and mobile screenshot files to the Trello card using `trello attachments add-file` or the available Trello attachment workflow.
   - Mention the screenshot attachments in the Trello comment when useful, but still attach the actual files.
   - Move the ticket forward:
     - Prefer an exact `Ready for Review` list.
     - If no exact list exists, use the board's development handoff column, usually `Ready for Testing`.
     - Discover list IDs with `trello lists list --board <board-id>` and move by ID.
   - Re-fetch the card after moving to verify `idList`.
   - Keep the Trello card URL handy for the final response.

9. Final response.
   - Include the PR URL, preview URL, Customizer URL, commit(s), and Trello movement.
   - Include the Trello ticket URL any time the ticket was commented on, moved, or otherwise updated.
   - State that desktop and mobile screenshots were uploaded to both GitHub and Trello, naming the destinations.
   - Mention any checks that failed due to unrelated existing issues and name the touched-file result.
   - Keep it concise.

## Existing PR Path Checklist

- [ ] Read Trello card, comments, attachments.
- [ ] Extract and inspect relevant Figma links.
- [ ] Find PR URL and branch.
- [ ] Switch to PR branch.
- [ ] Implement scoped fix.
- [ ] Validate locally.
- [ ] Push to existing preview theme.
- [ ] Browser QA preview.
- [ ] Capture desktop and mobile preview screenshots.
- [ ] Commit and push.
- [ ] Ensure PR description links to Trello.
- [ ] Upload screenshots to GitHub PR.
- [ ] Attach screenshots to Trello.
- [ ] Comment on Trello.
- [ ] Move card to review/testing handoff.

## Net-New Feature Checklist

- [ ] Read Trello card, comments, attachments.
- [ ] Extract and inspect relevant Figma links.
- [ ] Create branch off correct base.
- [ ] Implement scoped feature.
- [ ] Validate locally.
- [ ] Create unpublished `[DEV]` theme.
- [ ] Browser QA preview.
- [ ] Capture desktop and mobile preview screenshots.
- [ ] Commit and push.
- [ ] Create PR.
- [ ] Ensure PR description links to Trello.
- [ ] Upload screenshots to GitHub PR.
- [ ] Attach screenshots to Trello.
- [ ] Comment on Trello with PR, Preview, and Customizer.
- [ ] Move card to review/testing handoff.

## Trello Comment Template

```text
*PR:* <pr-url>

*Preview:* <page-preview-url>

*Customizer:* <customizer-url>

*Figma:* <figma-url if used>

<One short sentence or paragraph explaining what changed and what was verified.>
```

## Notes

- A "dev theme" for client review is usually an unpublished theme on the merchant store, not necessarily the `development` environment in `shopify.theme.toml`.
- Existing preview theme IDs in Trello comments are strong source-of-truth signals.
- Figma links can appear in Trello descriptions or comments; search both before deciding there is no design reference. Description links are the default source of truth unless a comment clearly supersedes them.
- Figma MCP design context is a reference, not an implementation authority. Match the visible design using the repo's theme architecture.
- Shopify generated JSON headers are not slop; preserve them on existing theme templates.
- If Theme Check is noisy, do not hide the noise. Filter for touched files and report both the repo-wide status and touched-file status.
