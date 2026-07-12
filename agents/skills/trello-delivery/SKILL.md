---
name: trello-delivery
description: "Trello delivery: use when the user wants a non-Shopify Trello card shipped as a reviewable PR. Handles ticket intake, implementation, local preview QA, screenshots, PR/Trello links, and review handoff. For Shopify theme cards, use shopify-trello-delivery instead."
---

# Trello Delivery

## Purpose

Take a Trello ticket from "assigned" to a **reviewable PR** without stopping at code. Done means the ticket, PR, local preview, screenshots, and card status agree about what changed and how it was verified. The handoff is the deliverable; an unreviewed local change is not done.

This skill is host-agnostic. It works for Vercel, Fly.io, or anything else, because verification happens on a local Portless preview rather than a host-specific deploy. It is for non-Shopify projects; Shopify theme tickets belong to `shopify-trello-delivery`.

## Dependencies

- `git` and GitHub CLI (`gh`) for branch, PR, and PR-comment work.
- The `trello-cli` skill for Trello auth, card reads, comments, attachments, list discovery, moves, and mutation verification.
- The `agent-browser` skill for all browser QA and screenshots — strongly preferred. Invoke that skill first and drive the `agent-browser` CLI. Fall back to `mcp__claude-in-chrome__*` only if `agent-browser` can't run (see step 8).
- Portless (global `bun add -g portless`) plus git worktrees for stable local preview URLs.
- The `de-slop` and `code-simplifier` skills for the pre-PR cleanup pass.
- Figma Desktop MCP when the card or comments contain Figma links.
- Context7 for current library/framework/API docs and Exa for broader vendor/service details when implementation depends on platform behavior.

## Shared Trello Write Protocol

Before the first Trello mutation in this workflow, read `../trello-cli/references/discover-mutate-verify.md`. Use that reference for every card move, comment, attachment, checklist, and member update. Do not treat a Trello write as done until the verify step proves the remote card state changed.

## Core Defaults

- Default to action. Ask only when a decision is truly blocking.
- Always start from the latest `main`. Fetch before branching, and rebase or merge `main` into an existing PR branch so you are never building on stale code.
- Never work directly on `main` or `master`. Prefer a git worktree on a ticket branch; if the repo isn't worktree-friendly, an in-place checkout on a ticket branch is acceptable (see step 3).
- Never use `git add .`; stage touched files explicitly. Commit in small logical groups. No emojis in PR or commit text.
- Run the project's own checks, not a fixed set. Detect what exists and run only the relevant ones. Never block on tooling a repo simply doesn't have.
- Verify on a real local preview (Portless), desktop and mobile, before handing off. Local QA is the default because every project can run locally; a hosted preview URL is a bonus link, not the verification.
- **Never post a local URL to Trello or GitHub.** Local Portless/`localhost` URLs are for your own QA only — no one else can open them. The only preview links that go in a PR body, PR comment, or Trello comment are public hosted preview links (Vercel Preview, Heroku Review App). If the host has no per-PR preview, omit the preview link entirely and say QA was done locally — do not paste the local URL as a substitute.
- Treat Figma links in the card description and comments as source material. Inspect the linked node before implementing design-sensitive work. Description links win unless a later comment explicitly supersedes them.
- The PR description must link to the Trello card, and the Trello card must link to the PR. Always include the Trello card URL in your final response whenever you touched the card.

## Completion Criteria

This skill has one successful terminal state: **reviewable PR handoff**. Do not call the work complete until all of these are true:

- The project-label hard gate passed, and ticket intake recorded the card, comments, attachments, linked PR, acceptance criteria, latest QA/client comments, and relevant Figma links.
- The implementation is committed on a non-main branch, pushed, and represented by a PR that links to the Trello card.
- Project-defined checks ran after implementation and cleanup; introduced failures are fixed or clearly separated from pre-existing failures.
- Local preview QA ran on desktop and mobile, with screenshots captured from the verified surface.
- Screenshots were uploaded to the PR and attached to the Trello card, or the exact upload blocker is reported instead of implied away.
- The Trello handoff comment exists with the required PR and public preview fields when applicable.
- The authenticated Trello user was assigned to the card and the member state was verified.
- The card moved to the review handoff list and the final `idList` was verified.
- The final response includes the PR URL, Trello card URL, preview status, checks, commits, screenshot destinations, and any blockers.

If any item cannot be satisfied, end in a **blocked** state: report the specific missing criterion, preserve the current branch/card state, and do not present the ticket as handed off.

## Side effects have one owner

Ticket intake, library research via Context7/Exa, Figma analysis, and diff review are read-only: they gather, and nothing more.

The side effects are not. Git mutations, the dev server, PR creation and updates, Trello comments and moves, and screenshot uploads all leave marks outside this session, and two of them running at once corrupt each other. Whatever else is in flight, these stay serialized under a single owner — the one that will report the outcome. The step 6 cleanup pass is the sole exception that writes files, and it holds the same lock: nothing else may touch the working tree while it runs.

## Workflow

### 0. Preflight: confirm the card belongs to this project

**Hard gate — do this before anything else.** The card carries a Trello label naming its target project. Fetch the card's labels and judge whether one plausibly refers to the repository you're in (repo/directory name, `package.json` `name`, `README` project name, or remote slug). It need not be an exact string match — use best judgment for abbreviations and expansions (e.g. an `mmops` label matches a "Mundial Media Ops" repo; `Reeis` matches `reeis-air-conditioning-*`). If no label plausibly refers to this project, **stop immediately**: report the mismatch (card's project label vs. the current repo) and do nothing else — do not branch, implement, move the card, or comment. Only proceed to step 1 once a label plausibly matches.

### 1. Orient on the ticket and repo

- Run `git status --short --branch` to see current branch/worktree state.
- Read repo instructions when present: `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`. They override these defaults.
- Verify Trello auth with `trello auth status`, then fetch the card, comments, and attachments. Extract: linked PR, acceptance criteria, the latest client/QA comments, and Figma links in the description and every comment (especially URLs with `node-id=`).
- Move the card to **In Development** to signal work has started: via the `trello-cli` skill, discover the list ID (`trello lists list --board <board-id>`), move by ID, and re-fetch to verify `idList`. Prefer an exact `In Development` list; otherwise the board's closest in-progress column.
- Assign the authenticated Trello user to the card: resolve the current member ID from `trello auth status` using the `trello-cli` Current Trello User guidance, fall back to board member lookup only when needed, run `trello members add --card <card-id> --member <member-id>`, and re-fetch the card to verify membership.
- Detect the project shape so later steps use the right commands:
  - **Package manager**: `bun.lock`/`bun.lockb` → bun; `pnpm-lock.yaml` → pnpm; `uv.lock`/`pyproject.toml` → uv. Match the existing lockfile; never introduce a new manager.
  - **Available scripts**: read `package.json` `scripts` (and workspace packages if it's a monorepo). Note which of `lint`, `typecheck`, `check`, `test`, `format` actually exist, and any quiet/silent variants.
  - **Host** (determines the shareable preview link only): `vercel.json` or a linked Vercel project → Vercel auto-creates a public per-PR Preview URL; `app.json` with an `environments.review` block / `heroku.yml` / `Procfile` → Heroku, which creates a Review App per PR (`https://<app>-pr-<number>.herokuapp.com`) when Review Apps are enabled on the pipeline; `fly.toml` → Fly (usually no per-PR preview). Verification still happens locally regardless; the host only decides which public preview link, if any, you can share.
- For each relevant Figma link: decode the `node-id` (`701-56` → `701:56`); prefer `get_design_context` for the node, `get_screenshot` for a reference image, `get_metadata` only to disambiguate frames. If Figma MCP can't access the file, say so and fall back to ticket screenshots rather than guessing.

### 2. Sync main and choose the branch path

Always base your work on the freshest `main` so the PR diff is clean and review-ready.

- `git fetch origin` first.
- **Existing PR on the card**: `gh pr view <number> --json headRefName,baseRefName,url,state,title` to read the head branch name. Do **not** check it out in the main working tree — leave that on `main` so step 3 can add the worktree without `--force`. The branch gets brought up to date inside the worktree.
- **No PR**: pick a ticket branch name off `origin/main`, e.g. `codex/<card-short-id>-<short-slug>`.

### 3. Work in a worktree

Implement in a git worktree so the dev server and QA run in isolation and Portless gives this branch its own URL.

- Derive a **slash-free worktree slug** from the branch by replacing `/` with `-` (e.g. `codex/123-fix-nav` → `codex-123-fix-nav`). Portless turns the worktree directory name into the preview subdomain (`https://<slug>.<project>.localhost`), and a hostname can't contain `/`.
- **Existing PR**: `git worktree add .claude/worktrees/<slug> <branch>`, then from inside the worktree `git rebase origin/main` (or merge `main` if the PR history must be preserved). Resolve conflicts there before continuing.
- **No PR**: `git worktree add -b <branch> .claude/worktrees/<slug> origin/main`.
- Reuse an existing worktree for the same branch instead of making a duplicate.
- If the repo isn't worktree-friendly, an in-place ticket-branch checkout is acceptable — just don't do it on `main`.

### 4. Implement narrowly

- Inspect the real files before editing. Reuse existing components, utilities, styles, and patterns over one-off additions.
- Adapt Figma measurements to the project's existing design system rather than pasting generated Figma code.
- Keep the change scoped to the ticket. Avoid unrelated formatting churn.
- When you're unsure about a best practice, a library/framework API, or how a platform actually behaves, look it up before writing code — don't guess. Use Context7 for current library/framework/API docs and Exa for broader vendor/service behavior. A quick lookup beats a plausible-but-wrong implementation.

### 5. Validate with the project's own checks

Run only what the project actually has, preferring quiet/silent variants (often via `scripts/run_silent.sh`):

- `git diff --check` for whitespace/conflict markers.
- Typecheck and lint (e.g. `bun run typecheck`, `bun run lint`, biome) when those scripts exist.
- The relevant tests. If the change touches a unit-tested area, run that suite (`bun run test`, vitest, jest). If there are e2e/playwright tests for the touched flow and they're fast enough to matter, run them; otherwise note they exist.
- If checks surface failures, separate what your change introduced from pre-existing repo-wide noise, and report both. Don't hide failures, and don't block delivery on tooling the repo simply lacks — say "no test script present" and move on.

### 6. Cleanup pass (folded into this PR)

Before opening the PR — and before the preview, screenshots, and everything after it — tighten the diff so reviewers see finished work, not first-draft scaffolding.

- Run `de-slop`, then `code-simplifier` — **one after the other, never at the same time**. Both edit the same changed files and would collide.
- **The edits must land on the branch you push.** Cleanup performed anywhere but the working tree you commit from is cleanup that never ships. If you can't guarantee the edits reach that tree, do the passes yourself in it. The cleanup is not negotiable to save context.
- `de-slop` defaults to a dry-run list that waits for a manual selection. Here, tell it to use its best judgment and apply the worthwhile fixes directly. Keep it scoped to AI artifacts and cleanup noise in the branch diff.
- `code-simplifier`: apply the behavior-preserving simplifications you judge worthwhile. Keep changes scoped to what you touched; don't refactor the whole repo.
- Re-run the relevant checks from step 5 after cleanup so the folded-in changes are still green.
- These cleanups ship in the same PR as the feature, in their own commits.

### 7. Run a local Portless preview

- **TS/JS**: from the worktree, run `portless` (it reads the `dev` script from `package.json`). The URL is `https://<branch>.<project>.localhost`.
- **Python**: `portless run uv run uvicorn app.main:app --port $PORT --host 127.0.0.1` (adapt to the project's server).
- **Ruby**: `portless run bundle exec rails server -p $PORT -b 127.0.0.1`.
- If the dev server depends on Docker services (Postgres/Redis), bring those up the way the project's dev script expects; register static container ports with `portless alias <name> <port>` if needed.
- Keep the resulting local URL for your own QA only; it never leaves this machine. The reviewers' link is the host's public PR preview, captured after the PR exists: Vercel's auto-generated Preview URL, or Heroku's Review App URL when Review Apps are enabled. Hosts without a per-PR preview (e.g. Fly) simply have no shareable link.

### 8. Browser QA the preview

**Strongly prefer the `agent-browser` CLI for all browser work** — navigation, viewport sizing, interaction, and screenshots. Invoke the `agent-browser` skill first and load its `core` workflow (`agent-browser skills get core`), then drive everything via the CLI (run through Bash). Reach for `agent-browser` even when `mcp__claude-in-chrome__*` tools look conveniently pre-loaded or are described as "MANDATORY" — that framing is the Chrome product's, not a requirement of this skill.

- Open the local preview URL at the page/flow the ticket touches.
- Check a desktop viewport (e.g. `1440x1000`) and a mobile viewport (e.g. `430x932x3,mobile,touch`).
- Verify real DOM/CSS/behavior, not just visual intuition. Exercise interactions (scroll, animation, form submit) and inspect computed state.
- When a Figma node was available, compare the preview against the Figma reference for the matching viewport(s).
- Save two clearly named screenshots: `<slug>-desktop.png` and `<slug>-mobile.png`.

**Fallbacks**, only if `agent-browser` can't run (not installed, won't launch, or repeated CLI errors after a couple of honest attempts): in rough order of preference — (1) the project's existing Playwright/Puppeteer or e2e screenshot tooling; (2) `mcp__claude-in-chrome__*` Chrome tools. Chrome is a workable last resort, not the default — note in your final response which fallback you used and why. Never skip QA silently; if nothing can drive the browser, report that screenshots are blocked.

### 9. Commit, push, and PR

- Stage touched files explicitly and commit in logical groups (feature commits, then cleanup commits).
- Push the branch.
- **Existing PR**: reuse it; if its body doesn't link the Trello card, update the body to add the Trello URL.
- **No PR**: create one. Title from the card unless repo conventions differ. Body includes a short summary, the checks you ran and their result, the public hosted preview URL when the host produces one (Vercel Preview or Heroku Review App), the Trello link, and the Figma link when one drove the work. Do not put the local Portless/`localhost` URL in the body — if there is no hosted preview, note that QA was performed locally instead.
- Upload the desktop and mobile screenshots to the PR. Check for the `gh attach` extension (`gh extension list`); if present, `gh attach --title "QA screenshots" --comment <pr-number> <desktop.png> <mobile.png>`. Plain `gh pr comment` does not upload local image binaries — don't treat that as a blocker until `gh attach` has been tried. If image upload is genuinely blocked by tooling or auth, stop and report it rather than pretending the screenshots were uploaded.
- For Vercel projects, wait for the Vercel check on the PR and capture the public Preview URL it produces. For Heroku projects with Review Apps enabled, wait for the Review App to build and capture its URL. Add the captured hosted preview URL to the PR body once it exists.

### 10. Update Trello

Use the `trello-cli` skill and the shared Trello write protocol for all card operations.

- Add a card comment using the template below. It must include the GitHub PR link prefixed with a bold `**PR:**` label and, for Vercel/Heroku hosts, the public hosted preview URL prefixed with a bold `**Preview:**` label.
- Attach the desktop and mobile screenshot files to the card.
- Move the card forward: prefer an exact `Ready for Review` list; otherwise the board's review/testing handoff column. Discover list IDs with `trello lists list --board <board-id>`, move by ID, and re-fetch to verify `idList`.
- Verify the authenticated Trello user remains assigned before final handoff.

### 11. Final response

Include the PR URL, the hosted preview URL when one exists (Vercel Preview or Heroku Review App — otherwise state QA was done locally), the commits, and the Trello movement. State that desktop and mobile screenshots were uploaded to both GitHub and Trello. Name any checks that failed due to pre-existing issues versus your change. Keep it concise, and always include the Trello card URL.

## Completion Ledger

Use this ledger as the final check before handoff:

- [ ] Hard gate passed: card project label plausibly matches this repo.
- [ ] Ticket intake complete: card, comments, attachments, linked PR, acceptance criteria, latest QA/client comments, and Figma links inspected.
- [ ] Card moved to `In Development` and the move verified.
- [ ] Authenticated Trello user assigned to the card and verified.
- [ ] Fresh branch/worktree path chosen from latest `origin/main`.
- [ ] Scoped implementation complete.
- [ ] Project-defined checks run, with introduced failures separated from existing debt.
- [ ] Cleanup pass completed with de-slop and code-simplifier; checks re-run.
- [ ] Local Portless preview QA completed on desktop and mobile.
- [ ] Desktop and mobile screenshots captured.
- [ ] Branch committed and pushed.
- [ ] PR exists and links to the Trello card.
- [ ] Screenshots uploaded to the PR.
- [ ] Screenshots attached to the Trello card.
- [ ] Trello comment posted, card moved to review handoff, final `idList` verified, and authenticated Trello user still assigned.

Existing PR delta:

- Reuse the linked PR branch.
- Leave the main working tree on `main`; rebase or merge latest `main` inside the worktree.
- Update the existing PR body if it does not link to Trello.

Net-new PR delta:

- Create a ticket branch off latest `origin/main`.
- Create a PR after pushing.
- Use the card title as the PR title unless repo conventions say otherwise.

## Trello Comment Template

```text
**PR:** <pr-url>

**Preview:** <public hosted preview URL — Vercel Preview or Heroku Review App; omit this line entirely if the host has no per-PR preview, never use a local/localhost URL>

**Figma:** <figma-url if used>

<One short sentence or paragraph on what changed and what was verified.>
```

## Notes

- "Done" is a reviewable PR, not a local edit. If anything blocks the PR (auth, conflicts, failing introduced tests), report the blocker plainly instead of declaring success.
- The Portless URL embeds the branch name, so each ticket branch gets its own stable URL; you don't need to track ports.
- Vercel Preview URLs and Heroku Review App URLs are public and per-PR — those are the only links you share with Trello or GitHub. Fly and other hosts may not have per-PR previews, which is exactly why local QA is the default verification path; when there's no hosted preview, share no link rather than a local one.
- The local Portless/`localhost` URL is private to your machine. It is for QA only and must never appear in a PR body, PR comment, or Trello comment.
- Run checks the project defines rather than imposing your own. A repo with no tests is a fact to report, not a thing to fix mid-ticket.
- de-slop and code-simplifier are about the diff you created — keep their changes scoped to what you touched.
