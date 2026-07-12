---
name: trello-qa
description: "Verify a developer's finished Trello ticket on a non-Shopify web app and render a verdict. Dogfood the posted preview (desktop + mobile) against the card's acceptance criteria, then PASS it (approve the PR, move to Ready for Release) or FAIL it (request changes, attach repro, reassign the dev, move to Development). Read-only: never implements, commits, or opens a PR. Use when asked to 'QA this card', 'test before release', or 'sign off on this ticket'. Shopify themes use shopify-trello-qa; building a ticket uses trello-delivery."
---

# Trello QA

## Purpose

Take a developer's finished ticket and decide whether it is releasable. The deliverable is a **verdict**, not code: the Trello card, the GitHub PR review, the QA report comment, and the evidence all agree on PASS or FAIL.

This skill is host-agnostic (Vercel, Fly.io, anything) and is for non-Shopify projects; Shopify theme tickets belong to `shopify-trello-qa`. It does the opposite job of `trello-delivery`: that skill *builds* a ticket into a PR; this one *verifies* a PR someone else built and moves the card forward or kicks it back.

**This skill is read-only on the codebase.** It never edits files, never commits, never pushes, and never changes a PR's code. Its only writes are to Trello (comment, attachment, checklist, assignment, move) and a single GitHub PR review (approve or request-changes).

## Dependencies

- The `trello-cli` skill for Trello auth, card/comment/checklist reads, comments, attachments, member assignment, list discovery, moves, and mutation verification.
- The `agent-browser` skill for all browser QA, viewport sizing, interaction, console/network inspection, and screenshots — strongly preferred. Invoke that skill first and drive the `agent-browser` CLI. Fall back to `mcp__claude-in-chrome__*` only if `agent-browser` can't run.
- The `dogfood` skill for systematic exploration of the touched surface, the regression sweep, and structured reproduction evidence (numbered steps, screenshots, repro video) on any failure.
- GitHub CLI (`gh`) to read the PR (read-only) and leave one PR review.
- Figma Desktop MCP when the card or comments contain Figma links, to compare the build against the design.
- Context7 / Exa only to confirm how a library or platform is *expected* to behave when a criterion hinges on it — never to change code.

## Shared Trello Write Protocol

Before the first Trello mutation in this workflow, read `../trello-cli/references/discover-mutate-verify.md`. Use that reference for every card move, comment, attachment, checklist, and member update. Do not treat a Trello write as done until the verify step proves the remote card state changed.

## Core Defaults

- **Read-only on code.** No edits, no commits, no pushes, no branch checkouts, no running a dev server. If you find yourself wanting to fix the bug, stop — QA reports it; the developer fixes it.
- **Verify against acceptance criteria, not vibes.** Extract every criterion (card description plus any Trello checklist) and judge each one explicitly PASS or FAIL with attached evidence. No criterion is "probably fine."
- **QA a provided, openable preview.** Use the hosted preview URL the developer posted on the card or PR (e.g. a Vercel Preview URL). **If there is no openable preview URL, do not check out code or run a server** — treat the card as blocked: comment asking the developer for a working preview link, reassign them, leave the card in review, and stop.
- **Desktop and mobile, every time**, plus a console-error and failed-request check on the touched surface.
- **Be regression-aware.** Don't only walk the happy path of the change; exercise the adjacent flows the change could plausibly break. This is where `dogfood` earns its keep.
- **Evidence or it didn't happen.** PASS produces desktop + mobile screenshots showing the criteria met. FAIL produces a full `dogfood`-style reproduction for each failing criterion: numbered steps, before/after screenshots, and a repro video/gif for interaction bugs.
- **PASS and FAIL are the only verdicts.** "Couldn't verify" is not a PASS or FAIL — it is a blocked handoff with a verified Trello comment explaining the reason.
- **Code-hygiene notes are non-blocking.** When you have GitHub repo access, note diff evidence that the developer skipped `code-simplifier` / `de-slop` (duplication, nested ternaries, slop comments, stray scratch files, etc.) as inline PR comments — but never let them change the PASS/FAIL verdict. Without GitHub access, fold them into the Trello comment. You observe these; you never run those skills or edit the code.
- **Discover the board's real column names; never assume them.** Boards differ (see Board Column Reference). Fetch list IDs and move by ID.
- Always include the Trello card URL in the final response.

## Completion Criteria

This skill has three terminal states: **PASS**, **FAIL**, or **blocked**. Choose exactly one.

PASS is complete only when every item is true:

- Project and QA-handoff gates passed.
- Card, comments, attachments, checklists, labels, members, PR link, preview URL, Figma links, acceptance criteria, and original developer were inspected.
- The provided preview opened; no local branch checkout or dev server was used.
- Every acceptance criterion was verified on desktop and mobile and marked PASS with evidence.
- Console/network checks, regression sweep, and Figma comparison when applicable found no release-blocking issue.
- Desktop and mobile proof screenshots were captured and attached to the Trello card.
- The PR was approved, including bundled non-blocking hygiene comments when present.
- The QA PASS comment exists, checklist items are checked when applicable, the card moved to Ready for Release, and the final `idList` was verified.

FAIL is complete only when every item is true:

- At least one acceptance criterion, console/network check, regression check, or applicable Figma comparison failed.
- Each failing criterion has a self-contained repro bundle: steps, expected/actual result, viewport, screenshots, and video/gif for interaction bugs.
- The PR has a request-changes review referencing the repro evidence, with hygiene comments bundled only as non-blocking notes when present.
- The QA FAIL comment exists, all repro evidence is attached to Trello, the original developer is reassigned, the card moved back to Development In Progress, and the final `idList` was verified.

Hard-gate failures are terminal reports, not blocked handoffs: wrong project or wrong column must stop without Trello mutation.

Trello-auth failures are terminal local reports, not blocked handoffs: stop, report the auth blocker, and do not retry Trello writes.

Blocked is complete only when the confirmed card cannot be verified before a verdict, such as missing/broken preview or inaccessible required source material. The blocked handoff must leave a Trello comment with the specific blocker, reassign the developer when the card needs their action, keep or return the card to the appropriate review/development state, verify any Trello write, and report the card URL in the final response.

## Side effects have one owner

Ticket intake (criteria, PR link, preview URL, Figma links, original developer), Figma reference capture, and PR-diff review for scope and missing-criteria signals are read-only: they gather, and nothing more.

The browser QA session, the verdict, the GitHub PR review, and every Trello comment, attachment, and move are not. They stay serialized under a single owner, so nothing races and **the verdict has exactly one author** — the one that watched the QA session firsthand.

## Workflow

### 0. Preflight: confirm the card belongs here and is ready for QA

**Hard gate.** Two checks before anything else:

1. **Project match.** The card carries a Trello label naming its target project. Judge whether one plausibly refers to this repo (directory name, `package.json` `name`, `README`, remote slug) — abbreviations and expansions count (an `mmops` label matches a "Mundial Media Ops" repo). If none plausibly matches, **stop**: report the mismatch and do nothing else.
2. **Ready for QA.** Confirm the card is actually in the development→QA handoff column (`Ready for Review`, or the board's closest handoff list). If it's still in development, already in `Ready for Release`, or shipped, **stop** and report — QA should not pull a card that wasn't handed off.

### 1. Orient on the ticket

- Verify Trello auth with `trello auth status`.
- Fetch the card, description, comments, attachments, checklists, labels, and members.
- Extract and record:
  - **The PR link** and **the preview/hosted URL** the developer posted.
  - **Acceptance criteria** — from the description and from any Trello checklist. If the card has a checklist of criteria, that becomes your QA checklist verbatim.
  - **Figma links** in the description and every comment (especially `node-id=` URLs). Description links win unless a later comment explicitly supersedes them.
  - **The original developer** — the PR author and/or the card assignee — so you can reassign them on a FAIL.
- Read repo instructions (`CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`) only to understand expected behavior. Change nothing.

### 2. Establish the preview (no code)

- Find an openable preview URL: the public hosted Preview on the PR (Vercel) or a preview URL in a Trello comment.
- **If nothing opens** (no hosted preview, link dead, host has no per-PR preview): take the **blocked path** — comment on the card asking the developer to provide a working preview/hosted URL, reassign them, leave the card in review, and stop. Do not check out the branch or start a server.
- For each relevant Figma link, decode the `node-id` (`701-56` → `701:56`); use `get_design_context` for the node and `get_screenshot` for a reference image. If Figma MCP can't open the file, say so and fall back to ticket screenshots.

### 3. Read the PR for scope (read-only)

- `gh pr view <number> --json headRefName,baseRefName,url,state,title,author,additions,deletions,files` and `gh pr diff <number>` to understand what actually changed.
- Use the diff to target the right surfaces and to spot gaps a black-box pass would miss: a criterion with no corresponding code change, missing tests for a tested area, removed handling. Do **not** check out the branch.

### 3b. Code-hygiene observation pass (GitHub only, non-blocking)

Only run this when the QA has GitHub access to the repo (confirm with `gh auth status` and a successful `gh pr view`). With no access, skip GitHub and record any observations for the Trello comment instead.

**Do not run `code-simplifier` or `de-slop`, and do not edit code.** You are only noting *evidence in the diff* that the developer skipped those passes. These observations are **never a reason to FAIL** — they're a courtesy heads-up kept separate from the acceptance-criteria verdict, so an approved card can still carry them.

Scan `gh pr diff <number>` for the tells those skills exist to catch:

- **Simplifier tells:** duplicated or near-duplicate logic (DRY), one function/component doing several jobs (SRP), deep nesting that wants early returns, nested ternaries, repeated computation or obvious N+1 loops, dead code, unclear names.
- **De-slop tells:** redundant comments or filler docstrings restating obvious code, comments inconsistent with the surrounding style, scratch files committed (`NOTES`/`PLAN`/`IDEAS`/`TODO.md`), `any` casts that only paper over types, defensive try/catch on trusted paths, mock-heavy tests with no real assertions, fake/uncited metrics.

Keep the bar high: flag clear, line-locatable instances, not stylistic preference. A clean diff gets no note.

**Where to post, in order of preference:**

1. **Inline on the offending lines, bundled into the verdict review.** Instead of the plain `gh pr review` call in step 7, create one review carrying both the verdict and the line comments: `gh api repos/<owner>/<repo>/pulls/<number>/reviews --method POST --input <payload.json>`, where the payload has `event` (`APPROVE` or `REQUEST_CHANGES`), the verdict `body`, and a `comments` array of `{ "path", "line", "side": "RIGHT", "body" }` — one per finding, each referencing a line present in the diff. Prefix each comment body with `code hygiene (non-blocking):`.
2. If inline anchoring is impractical, one PR review comment listing `file:line — note`.
3. If GitHub access is unavailable, a short **Code hygiene (non-blocking)** block in the Trello QA comment listing `file:line — note`.

### 4. Verify every acceptance criterion

This is the core of the job. Invoke the `dogfood` skill to drive the preview systematically, on a desktop viewport (`1440x1000`) and a mobile viewport (`430x932x3,mobile,touch`).

- For each acceptance criterion: reproduce the intended behavior on the preview, mark it PASS or FAIL, and capture evidence.
- **Console/network check:** with `agent-browser`, read the console and network panel on the touched surface; flag JS errors, failed requests, and broken assets the change introduced.
- **Figma compare:** for any visual criterion, compare the preview against the Figma reference at the matching viewport(s).
- **Regression sweep:** exercise the adjacent flows the diff could affect (shared component, shared route, shared state), not just the changed screen.

### 5. Capture evidence

- **PASS:** `<card-short>-desktop.png` and `<card-short>-mobile.png` showing the criteria satisfied.
- **FAIL:** one reproduction bundle per failing criterion from `dogfood` — numbered repro steps, before/after screenshots, and a gif/video for interaction-driven bugs. This is what the developer will work from, so make it self-contained.

### 6. Render the verdict

- **PASS** only if *every* acceptance criterion is met, no console errors were introduced, no regressions surfaced, and the design matches when Figma applies.
- Otherwise **FAIL**. One unmet criterion is a FAIL — partial credit is not releasable.

### 7a. PASS path

- **GitHub:** approve the PR — note what was verified, the viewports, and the preview URL. If step 3b found hygiene tells, post the approval and the inline `code hygiene (non-blocking):` comments as one review via the `reviews` API; otherwise a plain `gh pr review <number> --approve --body "<short sign-off>"`.
- **Trello (discover → mutate → verify):**
  - Use the shared Trello write protocol for every comment, checklist update, attachment, member change, and move.
  - Post the **QA PASS** report comment (template below).
  - Check off the verified items if the card uses a Trello acceptance-criteria checklist.
  - Attach `<card-short>-desktop.png` and `<card-short>-mobile.png` to the card.
  - Move the card to **Ready for Release** (`trello lists list --board <board-id>`, move by ID, re-fetch to confirm `idList`).

### 7b. FAIL path

- **GitHub:** request changes on the PR referencing the repro evidence. If step 3b found hygiene tells, bundle the request-changes verdict and the inline `code hygiene (non-blocking):` comments into one review via the `reviews` API; otherwise a plain `gh pr review <number> --request-changes --body "<failing criteria summary>"`. (Hygiene notes ride along but are not the reason for the changes request — the failing criteria are.)
- **Trello (discover → mutate → verify):**
  - Use the shared Trello write protocol for every comment, attachment, member change, and move.
  - Post the **QA FAIL** report comment (template below): each failing criterion with its numbered repro steps.
  - Attach every repro screenshot and video to the card.
  - Reassign the original developer (`trello members add --card <card-id> --member <member-id>`).
  - Move the card back to **Development In Progress** (discover ID, move, re-fetch to confirm).

### 8. Final response

State the terminal state (PASS, FAIL, or blocked), which criteria passed and which failed when a verdict was possible, the viewports tested, the preview URL used, where the card moved, and that screenshots/repro or blocker evidence were posted to both the PR review and the Trello card as applicable. Keep it concise and always include the Trello card URL.

## PASS Checklist

- [ ] Card's project label matches this repo; stop if not.
- [ ] Card is in the QA handoff column; stop if not.
- [ ] Read card, comments, checklists; extract criteria, PR link, preview URL, Figma links, original developer.
- [ ] Open the developer's preview URL (blocked path if none opens).
- [ ] Read the PR diff for scope (no checkout).
- [ ] (GitHub access) Scan diff for skipped code-simplifier/de-slop tells; post inline non-blocking PR comments.
- [ ] Dogfood every acceptance criterion, desktop and mobile.
- [ ] Console/network check; regression sweep; Figma compare where it applies.
- [ ] All criteria met → capture desktop + mobile proof screenshots.
- [ ] Approve the PR (bundle hygiene comments into the review if any) with sign-off.
- [ ] QA PASS comment; check off criteria; attach screenshots to card.
- [ ] Move card to Ready for Release; verify `idList`.

## FAIL Checklist

- [ ] Card's project label matches this repo; stop if not.
- [ ] Card is in the QA handoff column; stop if not.
- [ ] Read card, comments, checklists; extract criteria, PR link, preview URL, Figma links, original developer.
- [ ] Open the developer's preview URL (blocked path if none opens).
- [ ] Read the PR diff for scope (no checkout).
- [ ] (GitHub access) Scan diff for skipped code-simplifier/de-slop tells; post inline non-blocking PR comments.
- [ ] Dogfood every acceptance criterion, desktop and mobile.
- [ ] Capture a full repro bundle (steps + screenshots + video) per failing criterion.
- [ ] Request changes on the PR (bundle hygiene comments into the review if any) summarizing failures.
- [ ] QA FAIL comment with repro; attach all repro evidence to card.
- [ ] Reassign the original developer.
- [ ] Move card back to Development In Progress; verify `idList`.

## QA Report Comment Templates

PASS:

```text
**QA: PASS** ✅

**PR:** <pr-url>
**Preview:** <preview-url used for QA>
**Figma:** <figma-url if compared>
**Viewports:** desktop 1440x1000, mobile 430x932

**Acceptance criteria**
- [x] <criterion 1>
- [x] <criterion 2>

No console errors introduced; no regressions found in adjacent flows. Desktop and mobile screenshots attached. Approving the PR and moving to Ready for Release.

<!-- Include only when you have no GitHub access and found hygiene tells: -->
**Code hygiene (non-blocking)** — looks like code-simplifier/de-slop may not have been run:
- <file:line — note>
```

FAIL:

```text
**QA: FAIL** ❌

**PR:** <pr-url>
**Preview:** <preview-url used for QA>
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

Requested changes on the PR and moved back to Development In Progress, reassigned to @<developer>.

<!-- Include only when you have no GitHub access and found hygiene tells: -->
**Code hygiene (non-blocking)** — looks like code-simplifier/de-slop may not have been run:
- <file:line — note>
```

## Board Column Reference

Discover real list names per board; these are the current defaults:

- **Non-Shopify boards (e.g. Node.js Projects):** QA pulls from **Ready for Review** → PASS moves to **Ready for Release** → FAIL moves back to **Development In Progress**.
- Other non-Shopify boards (React Native, Rails, Wordpress) follow the same handoff→release / handoff→development shape; confirm the exact list names with `trello lists list --board <board-id>` before moving.

## Notes

- The verdict is the deliverable. A green PR that nobody verified against the criteria is not QA'd.
- "Blocked / can't verify" is never a silent pass. Hand the card back with the specific reason.
- Never become the developer mid-ticket. If the fix is obvious, write it up as a precise repro and FAIL — don't edit code.
- Read the PR diff to verify the *right* things changed, but judge behavior on the running preview, not on the diff alone.
- One unmet acceptance criterion fails the whole card; release is all-or-nothing.
