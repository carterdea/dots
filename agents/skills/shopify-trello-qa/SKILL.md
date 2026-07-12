---
name: shopify-trello-qa
description: "Verify a developer's finished Shopify theme ticket and render a verdict. Dogfood the posted preview theme and Customizer (desktop + mobile) against the card's acceptance criteria and Figma, then PASS it (approve the PR, move to Ready for Release) or FAIL it (request changes, attach repro, reassign the dev, move to Development). Read-only: never implements, commits, deploys, or opens a PR. Use when asked to 'QA this Shopify card', 'verify the Ready for Testing card', or 'sign off on this theme ticket'. Non-Shopify apps use trello-qa; building a ticket uses shopify-trello-delivery."
---

# Shopify Trello QA

## Purpose

Take a developer's finished Shopify theme ticket and decide whether it is releasable. The deliverable is a **verdict**, not theme code: the Trello card, the GitHub PR review, the QA report comment, and the evidence all agree on PASS or FAIL.

This skill is for Shopify theme tickets; non-Shopify web apps belong to `trello-qa`. It does the opposite job of `shopify-trello-delivery`: that skill *builds* a theme change, deploys a preview, and opens a PR; this one *verifies* a preview theme someone else deployed and moves the card forward or kicks it back.

**This skill is read-only on the theme.** It never edits Liquid/assets, never commits, never pushes, never runs `shopify theme push` or any deploy, and never changes a PR's code. Its only writes are to Trello (comment, attachment, checklist, assignment, move) and a single GitHub PR review (approve or request-changes).

## Dependencies

- The `trello-cli` skill for Trello auth, Shopify Projects board verification, card/comment/checklist reads, comments, attachment listing/download/inspection, member assignment, list discovery, moves, and mutation verification.
- The `agent-browser` skill for all browser QA, viewport sizing, interaction, console/network inspection, and screenshots — strongly preferred. Invoke that skill first and drive the `agent-browser` CLI. Fall back to `mcp__claude-in-chrome__*` only if `agent-browser` can't run.
- The `dogfood` skill for systematic exploration of the touched surface, the regression sweep, and structured reproduction evidence (numbered steps, screenshots, repro video) on any failure.
- GitHub CLI (`gh`) to read the PR (read-only) and leave one PR review.
- The Shopify dev / AI Toolkit skills (`shopify-dev`, `shopify-liquid`, `shopify-admin`, `shopify-storefront-graphql`) only to confirm how a theme feature or app is *expected* to behave — never to change or deploy the theme. (Do **not** use `shopify-dev-theme`; QA does not create or deploy themes.)
- Figma Desktop MCP when the card or comments contain Figma links, to compare the build against the design.

## Shared Trello Write Protocol

Before the first Trello mutation in this workflow, read `../trello-cli/references/discover-mutate-verify.md`. Use that reference for every card move, comment, attachment, checklist, and member update. Do not treat a Trello write as done until the verify step proves the remote card state changed.

## Core Defaults

- **Read-only on the theme.** No edits, no commits, no `shopify theme push`, no theme creation, no dev server. If you want to fix the bug, stop — QA reports it; the developer fixes it.
- **Verify against acceptance criteria, not vibes.** Extract every criterion (card description plus any Trello checklist) and judge each one explicitly PASS or FAIL with attached evidence.
- **QA the preview theme the developer posted.** Open the page-specific preview URL (including `preview_theme_id=<id>` and any path/hash) and the Customizer URL from the Trello comment or PR. **If no preview theme URL opens** (missing, expired, deleted, theme-limit reaped), do not deploy your own — treat the card as blocked: comment asking the developer to re-deploy and post a working preview theme URL, reassign them, leave the card in review, and stop.
- **Desktop and mobile, every time**, plus a console-error and failed-request check. If the deploy URL omits `www` but customers see `www`, test the canonical storefront URL.
- **Be regression-aware.** Exercise adjacent sections/templates the change could break (shared snippet, shared section settings, global CSS), not just the changed surface.
- **Evidence or it didn't happen.** PASS produces desktop + mobile screenshots from the preview theme URL showing the criteria met. FAIL produces a full `dogfood`-style reproduction per failing criterion: numbered steps, before/after screenshots, repro video for interaction bugs.
- **PASS and FAIL are the only verdicts.** "Couldn't verify" is not a PASS or FAIL — it is a blocked handoff with a verified Trello comment explaining the reason.
- **Code-hygiene notes are non-blocking.** When you have GitHub repo access, note diff evidence that the developer skipped `code-simplifier` / `de-slop` (duplicated Liquid/JS, nested ternaries, slop comments, stray scratch files, etc.) as inline PR comments — but never let them change the PASS/FAIL verdict. Without GitHub access, fold them into the Trello comment. You observe these; you never run those skills or edit the theme. (Shopify-generated JSON headers are not slop — don't flag them.)
- **Always use the Shopify Projects board.** Its board ID is `60ec9752cc991401c1c7c327`; verify that ID still resolves to the open board named `Shopify Projects`, confirm the card belongs to it, and use that board ID for list discovery and moves.
- **Always inspect Trello card attachments before QA.** Download every accessible attachment to a per-card directory under `/tmp`, inspect the downloaded files or linked resources, and use relevant briefs, screenshots, PDFs, zips, and image references as source material for the verdict.
- **Discover the board's real column names; never assume them.** Shopify boards use different list names than Node boards (see Board Column Reference). Fetch list IDs from the Shopify Projects board and move by ID.
- Always include the Trello card URL in the final response.

## Completion Criteria

This skill has three terminal states: **PASS**, **FAIL**, or **blocked**. Choose exactly one.

PASS is complete only when every item is true:

- Shopify Projects board, project-label, and QA-handoff gates passed.
- Card, comments, attachments, checklists, labels, members, PR link, preview theme URL, Customizer URL, `preview_theme_id`, Figma links, acceptance criteria, and original developer were inspected.
- Attachments were downloaded to `/tmp/shopify-trello-qa-<card-short-id>/` and inspected.
- The developer's preview theme and Customizer opened; no branch checkout, theme creation, theme push, or dev server was used.
- Every acceptance criterion was verified on desktop and mobile and marked PASS with evidence.
- Console/network checks, regression sweep, Customizer checks, and Figma comparison when applicable found no release-blocking issue.
- Desktop and mobile proof screenshots were captured from the preview theme URL and attached to the Trello card.
- The PR was approved, including bundled non-blocking hygiene comments when present.
- The QA PASS comment exists, checklist items are checked when applicable, the card moved to Ready for Release, and the final `idList` was verified.

FAIL is complete only when every item is true:

- At least one acceptance criterion, console/network check, regression check, Customizer check, or applicable Figma comparison failed.
- Each failing criterion has a self-contained repro bundle: steps, expected/actual result, viewport, preview URL, screenshots, and video/gif for interaction bugs.
- The PR has a request-changes review referencing the repro evidence, with hygiene comments bundled only as non-blocking notes when present.
- The QA FAIL comment exists, all repro evidence is attached to Trello, the original developer is reassigned, the card moved back to Development in Progress, and the final `idList` was verified.

Hard-gate failures are terminal reports, not blocked handoffs: wrong board, wrong project, or wrong column must stop without Trello mutation.

Trello-auth failures are terminal local reports, not blocked handoffs: stop, report the auth blocker, and do not retry Trello writes.

Blocked is complete only when the confirmed card cannot be verified before a verdict, such as missing/broken preview theme, missing Customizer URL needed for the criteria, or inaccessible required source material. The blocked handoff must leave a Trello comment with the specific blocker, reassign the developer when the card needs their action, keep or return the card to the appropriate review/development state, verify any Trello write, and report the card URL in the final response.

## Side effects have one owner

Ticket intake (criteria, PR link, preview theme URL, Customizer URL, `preview_theme_id`, Figma links, original developer), Figma reference capture, and PR-diff review for scope and missing-criteria signals are read-only: they gather, and nothing more.

The browser QA session, the verdict, the GitHub PR review, and every Trello comment, attachment, and move are not. They stay serialized under a single owner, so nothing races and **the verdict has exactly one author** — the one that watched the QA session firsthand.

## Workflow

### 0. Preflight: confirm the card belongs here and is ready for QA

**Hard gate.** Three checks before anything else:

1. **Shopify Projects board.** Verify Trello auth with `trello auth status`, then use the hardcoded **Shopify Projects** board ID: `60ec9752cc991401c1c7c327`. Verify that board ID still resolves to the open board named `Shopify Projects`, for example with `trello boards list` filtered by ID or a direct board read if the CLI supports it. If the ID is not visible or no longer resolves to `Shopify Projects`, fall back to `trello search boards --query "Shopify Projects"` or `trello boards list` and require one exact open-board match before proceeding. Fetch the card and confirm its board ID matches `60ec9752cc991401c1c7c327`. If it does not, **stop** and report the board mismatch.
2. **Project match.** Judge whether a card label plausibly refers to this repo (directory name, `shopify.theme.toml` store, `README`, remote slug) — abbreviations count (a `Reeis` label matches `reeis-air-conditioning-shopify`). If none matches, **stop** and report the mismatch.
3. **Ready for QA.** Confirm the card is in the development→QA handoff column (`Ready for Testing`, or the board's closest handoff list on board `60ec9752cc991401c1c7c327`). If it's still in development, already in `Ready for Release`, or shipped, **stop** and report.

### 1. Orient on the ticket

- Check `shopify.theme.toml` for store/environment context (read-only).
- Fetch the card, description, comments, attachments, checklists, labels, and members from the confirmed **Shopify Projects** card.
- Follow the attachment download workflow in the `trello-cli` skill, using `/tmp/shopify-trello-qa-<card-short-id>/` as the output directory. Inspect all accessible attachments before QA and record findings for the verdict.
- Extract and record:
  - **The PR link**, the **preview theme URL**, the **Customizer URL**, and the **`preview_theme_id`** the developer posted.
  - **Acceptance criteria** — from the description and any Trello checklist. A criteria checklist becomes your QA checklist verbatim.
  - **Figma links** in the description and every comment (especially `node-id=` URLs). Description links win unless a later comment explicitly supersedes them.
  - **The original developer** — PR author and/or card assignee — for reassignment on a FAIL.
- Read repo instructions (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`) only for expected behavior. Change nothing.

### 2. Establish the preview theme (no deploy)

- Open the page-specific preview URL with `preview_theme_id=<id>` and any relevant path/hash, plus the Customizer URL.
- **If nothing opens** (theme gone, expired, link broken): take the **blocked path** — comment asking the developer to re-deploy and post a working preview theme URL, reassign them, leave the card in review, and stop. Do not create or push a theme.
- For each relevant Figma link, decode the `node-id` (`701-56` → `701:56`); use `get_design_context` for the node and `get_screenshot` for a reference image. If the Figma file has separate desktop and mobile frames, capture both. If Figma MCP can't open the file, say so and fall back to ticket screenshots.

### 3. Read the PR for scope (read-only)

- `gh pr view <number> --json headRefName,baseRefName,url,state,title,author,additions,deletions,files` and `gh pr diff <number>` to understand what changed.
- Use the diff to target the right sections/templates and to spot gaps: a criterion with no matching Liquid change, a removed setting, preserved-vs-broken Shopify JSON headers. Do **not** check out the branch.

### 3b. Code-hygiene observation pass (GitHub only, non-blocking)

Only run this when the QA has GitHub access to the repo (confirm with `gh auth status` and a successful `gh pr view`). With no access, skip GitHub and record any observations for the Trello comment instead.

**Do not run `code-simplifier` or `de-slop`, and do not edit the theme.** You are only noting *evidence in the diff* that the developer skipped those passes. These observations are **never a reason to FAIL** — they're a courtesy heads-up kept separate from the acceptance-criteria verdict, so an approved card can still carry them.

Scan `gh pr diff <number>` for the tells those skills exist to catch:

- **Simplifier tells:** duplicated/near-duplicate Liquid or JS (DRY), a snippet/section doing several jobs (SRP), deep nesting that wants early returns, nested ternaries, repeated `assign`/loops that could be hoisted, dead code, one-off inline styles where a theme token/class exists, unclear names.
- **De-slop tells:** redundant comments or filler restating obvious code, comments inconsistent with the surrounding style, scratch files committed (`NOTES`/`PLAN`/`IDEAS`/`TODO.md`), `any` casts in theme JS that only paper over types, defensive guards on trusted paths, mock-heavy tests with no real assertions, fake/uncited metrics.

Do **not** flag Shopify-generated JSON schema headers — those are expected, not slop. Keep the bar high: flag clear, line-locatable instances, not stylistic preference. A clean diff gets no note.

**Where to post, in order of preference:**

1. **Inline on the offending lines, bundled into the verdict review.** Instead of the plain `gh pr review` call in step 7, create one review carrying both the verdict and the line comments: `gh api repos/<owner>/<repo>/pulls/<number>/reviews --method POST --input <payload.json>`, where the payload has `event` (`APPROVE` or `REQUEST_CHANGES`), the verdict `body`, and a `comments` array of `{ "path", "line", "side": "RIGHT", "body" }` — one per finding, each referencing a line present in the diff. Prefix each comment body with `code hygiene (non-blocking):`.
2. If inline anchoring is impractical, one PR review comment listing `file:line — note`.
3. If GitHub access is unavailable, a short **Code hygiene (non-blocking)** block in the Trello QA comment listing `file:line — note`.

### 4. Verify every acceptance criterion

Invoke the `dogfood` skill to drive the preview theme systematically, on a desktop viewport (`1440x1000`) and a mobile viewport (`430x932x3,mobile,touch`).

- For each acceptance criterion: reproduce the intended behavior on the preview theme, mark PASS or FAIL, capture evidence.
- **Console/network check:** with `agent-browser`, read the console and network panel; flag JS errors, failed requests, broken/404 assets the change introduced.
- **Figma compare:** for visual criteria, compare the preview against the Figma reference at the matching viewport(s); use both desktop and mobile frames when they exist.
- **Regression sweep:** exercise adjacent sections/templates and the Customizer settings the change exposes, not just the changed screen.

### 5. Capture evidence

- **PASS:** `<card-short>-desktop.png` and `<card-short>-mobile.png` taken from the preview theme URL (including `preview_theme_id`), showing the criteria met. Name them so it's clear they are implementation screenshots, not Figma references.
- **FAIL:** one reproduction bundle per failing criterion from `dogfood` — numbered repro steps, before/after screenshots, and a gif/video for interaction bugs. Self-contained so the developer can act on it.

### 6. Render the verdict

- **PASS** only if *every* acceptance criterion is met, no console errors were introduced, no regressions surfaced, and the design matches the Figma reference where it applies.
- Otherwise **FAIL**. One unmet criterion fails the card.

### 7a. PASS path

- **GitHub:** approve the PR — note what was verified, the viewports, the preview theme URL. If step 3b found hygiene tells, post the approval and the inline `code hygiene (non-blocking):` comments as one review via the `reviews` API; otherwise a plain `gh pr review <number> --approve --body "<short sign-off>"`.
- **Trello (discover → mutate → verify):**
  - Use the shared Trello write protocol for every comment, checklist update, attachment, member change, and move.
  - Post the **QA PASS** report comment (template below).
  - Check off verified items if the card uses a Trello acceptance-criteria checklist.
  - Attach `<card-short>-desktop.png` and `<card-short>-mobile.png` to the card.
  - Move the card to **Ready for Release** (`trello lists list --board 60ec9752cc991401c1c7c327`, move by ID, re-fetch to confirm `idList`).

### 7b. FAIL path

- **GitHub:** request changes on the PR referencing the repro evidence. If step 3b found hygiene tells, bundle the request-changes verdict and the inline `code hygiene (non-blocking):` comments into one review via the `reviews` API; otherwise a plain `gh pr review <number> --request-changes --body "<failing criteria summary>"`. (Hygiene notes ride along but are not the reason for the changes request — the failing criteria are.)
- **Trello (discover → mutate → verify):**
  - Use the shared Trello write protocol for every comment, attachment, member change, and move.
  - Post the **QA FAIL** report comment (template below): each failing criterion with its numbered repro steps.
  - Attach every repro screenshot and video to the card.
  - Reassign the original developer (`trello members add --card <card-id> --member <member-id>`).
  - Move the card back to **Development in Progress** (`trello lists list --board 60ec9752cc991401c1c7c327`, move by ID, re-fetch to confirm).

### 8. Final response

State the terminal state (PASS, FAIL, or blocked), which criteria passed and which failed when a verdict was possible, the viewports tested, the preview theme URL used, where the card moved, and that screenshots/repro or blocker evidence were posted to both the PR review and the Trello card as applicable. Keep it concise and always include the Trello card URL.

## PASS Checklist

- [ ] Verify Shopify Projects board ID `60ec9752cc991401c1c7c327` and confirm the card belongs to it; stop if not.
- [ ] Card's project label matches this repo; stop if not.
- [ ] Card is in the QA handoff column (Ready for Testing); stop if not.
- [ ] Read card, comments, checklists; extract criteria, PR link, preview theme URL, Customizer URL, `preview_theme_id`, Figma links, original developer.
- [ ] List, download to `/tmp/shopify-trello-qa-<card-short-id>/`, and inspect attachments.
- [ ] Open the developer's preview theme + Customizer URLs (blocked path if none opens).
- [ ] Read the PR diff for scope (no checkout).
- [ ] (GitHub access) Scan diff for skipped code-simplifier/de-slop tells; post inline non-blocking PR comments.
- [ ] Dogfood every acceptance criterion, desktop and mobile.
- [ ] Console/network check; regression sweep; Figma compare where it applies.
- [ ] All criteria met → capture desktop + mobile proof screenshots from the preview theme URL.
- [ ] Approve the PR (bundle hygiene comments into the review if any) with sign-off.
- [ ] QA PASS comment; check off criteria; attach screenshots to card.
- [ ] Move card to Ready for Release; verify `idList`.

## FAIL Checklist

- [ ] Verify Shopify Projects board ID `60ec9752cc991401c1c7c327` and confirm the card belongs to it; stop if not.
- [ ] Card's project label matches this repo; stop if not.
- [ ] Card is in the QA handoff column (Ready for Testing); stop if not.
- [ ] Read card, comments, checklists; extract criteria, PR link, preview theme URL, Customizer URL, `preview_theme_id`, Figma links, original developer.
- [ ] List, download to `/tmp/shopify-trello-qa-<card-short-id>/`, and inspect attachments.
- [ ] Open the developer's preview theme + Customizer URLs (blocked path if none opens).
- [ ] Read the PR diff for scope (no checkout).
- [ ] (GitHub access) Scan diff for skipped code-simplifier/de-slop tells; post inline non-blocking PR comments.
- [ ] Dogfood every acceptance criterion, desktop and mobile.
- [ ] Capture a full repro bundle (steps + screenshots + video) per failing criterion.
- [ ] Request changes on the PR (bundle hygiene comments into the review if any) summarizing failures.
- [ ] QA FAIL comment with repro; attach all repro evidence to card.
- [ ] Reassign the original developer.
- [ ] Move card back to Development in Progress; verify `idList`.

## QA Report Comment Templates

PASS:

```text
**QA: PASS** ✅

**PR:** <pr-url>
**Preview:** <preview-theme-url with preview_theme_id>
**Customizer:** <customizer-url>
**Figma:** <figma-url if compared>
**Viewports:** desktop 1440x1000, mobile 430x932

**Acceptance criteria**
- [x] <criterion 1>
- [x] <criterion 2>

No console errors introduced; no regressions in adjacent sections. Desktop and mobile screenshots attached. Approving the PR and moving to Ready for Release.

<!-- Include only when you have no GitHub access and found hygiene tells: -->
**Code hygiene (non-blocking)** — looks like code-simplifier/de-slop may not have been run:
- <file:line — note>
```

FAIL:

```text
**QA: FAIL** ❌

**PR:** <pr-url>
**Preview:** <preview-theme-url with preview_theme_id>
**Customizer:** <customizer-url>
**Figma:** <figma-url if compared>
**Viewports:** desktop 1440x1000, mobile 430x932

**Acceptance criteria**
- [x] <criterion that passed>
- [ ] <criterion that failed> — see repro below

**Issue 1 — <short title>** (<viewport>)
1. <step>
2. <step>
3. Expected: <…>  Actual: <…>
(screenshots / repro video attached)

Requested changes on the PR and moved back to Development in Progress, reassigned to @<developer>.

<!-- Include only when you have no GitHub access and found hygiene tells: -->
**Code hygiene (non-blocking)** — looks like code-simplifier/de-slop may not have been run:
- <file:line — note>
```

## Board Column Reference

Discover real list names per board; these are the current Shopify defaults:

- **Shopify Projects board:** QA pulls from **Ready for Testing** → PASS moves to **Ready for Release** → FAIL moves back to **Development in Progress** (note the lowercase "in"; there is also a **Blocked** column if a card is unverifiable for reasons outside the developer's control).
- Confirm the exact list names with `trello lists list --board 60ec9752cc991401c1c7c327` before moving — Shopify boards use "Ready for Testing," not "Ready for Review."

## Notes

- The verdict is the deliverable. A deployed preview theme nobody verified against the criteria is not QA'd.
- "Blocked / can't verify" is never a silent pass. Hand the card back with the specific reason (often an expired or theme-limit-reaped preview theme).
- Never become the developer mid-ticket. If the fix is obvious, write a precise repro and FAIL — don't edit Liquid or push a theme.
- Shopify generated JSON headers are not slop; a missing header on an existing template is a regression worth flagging, not a thing to fix yourself.
- Read the PR diff to verify the *right* sections changed, but judge behavior on the running preview theme, not on the diff alone.
- One unmet acceptance criterion fails the whole card; release is all-or-nothing.
