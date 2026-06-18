---
name: gh-address-pr-comments
description: Resolve actionable GitHub pull request review feedback and watch for new comments. Use when the user wants to inspect or continuously poll unresolved review threads, requested changes, inline comments, or PR conversation comments, then automatically implement valid fixes while filtering bots, outdated comments, duplicates, and non-actionable noise. Stop watch loops when the PR has a thumbs-up approval reaction.
---

# Address PR Comments

Resolve actionable PR comments without babysitting. Prefer unresolved review threads over flat comment lists; flat comments lose resolution state and inline context.

Default to autonomous watch mode unless the user explicitly asks for a one-shot review or manual selection.

## Steps

1. Resolve the PR.
   - If the user supplied a PR number/URL, use it.
   - Otherwise confirm `gh auth status`, then try:
     `gh pr view --json number,state,headRefName,url -q 'select(.state=="OPEN") | .number'`
   - If that returns nothing, try:
     `gh pr list --head "$(git branch --show-current)" --state open --json number -q '.[0].number'`
   - Only ask if lookup fails or returns multiple PRs.

2. Check out the PR.
   - Run `gh pr checkout {PR_NUMBER}` unless already on that PR branch.

3. Fetch thread-aware review data.
   - Resolve `SKILL_DIR` to this skill's installed directory, then run `uv run "$SKILL_DIR/scripts/fetch_comments.py" --pr {PR_NUMBER}`. The helper fetches `reviewThreads`, `isResolved`, `isOutdated`, file paths, line anchors, reviews, top-level PR comments, and PR reactions.
   - If `approval.has_thumbs_up` is true, treat the PR as approved and exit the watch loop.
   - `approval.has_thumbs_up` must mean a thumbs-up from an app/bot login that looks like Codex/OpenAI/ChatGPT. Treat unrelated teammate or bot thumbs-up reactions as informational only.
   - Use flat reads only for quick fallback or top-level summaries:
     `gh pr view {PR_NUMBER} --json title,body,state,author,headRefName,baseRefName,url,reviews`
     `gh api repos/{OWNER}/{REPO}/pulls/{PR_NUMBER}/comments --jq '.[] | {id, path, line, position, body, user: .user.login, user_type: .user.type}'`
     `gh api repos/{OWNER}/{REPO}/issues/{PR_NUMBER}/comments --jq '.[] | {id, body, user: .user.login, user_type: .user.type}'`
   - Do not treat flat PR comments as complete review-thread state.

4. Filter noise before classifying. Skip entirely; do not list or act on:
   - Resolved review threads.
   - Outdated review threads/comments (`isOutdated == true` or flat review comments where `position` is `null`).
   - Vercel bot comments (`vercel[bot]`, `vercel-bot`, or preview/deployment status text).
   - Bare agent mentions: body is just `@claude`, `@codex`, or short variants like `@codex review`, `@claude please review`, `@claude take a look`. Heuristic: strip mentions + whitespace; if <= about 3 words remain and none describe a change, skip.
   - Already addressed this session. Briefly note these as "already addressed" in the final summary rather than re-applying or re-verifying.
   - Duplicates of another thread; keep the clearest active thread as canonical.

5. Classify each actionable thread/comment by author.
   - **Human** (`user_type == "User"` or non-bot author in GraphQL): trust default. Assume correct unless obviously wrong. Verify scope and intent, then apply.
   - **Bot** (`user_type == "Bot"` or login matches `cursor[bot]`, `chatgpt-codex-connector`, `claude[bot]`, `coderabbitai[bot]`, `github-actions[bot]`, `*-bot`, `*[bot]`): skeptical default. Bots hallucinate, flag non-issues, miss context. For each bot comment:
     - Read cited code + surrounding context before acting.
     - Ask: is the claim factually correct? Does the fix improve code or just silence the bot?
     - Reject if: false positive, stylistic noise, conflicts with project patterns, or suggests a broken refactor.
     - If rejected, note the reason in summary. Do not "address" via a no-op reply commit.

6. Decide what to fix.
   - Autonomous default: fix every valid actionable item. Do not ask the user to pick items.
   - Stay skeptical of bots, but apply bot feedback when the cited issue is factually correct and the fix improves the code.
   - Ask only when the comment is ambiguous, conflicting, destructive, requires product judgment, or would cause a behavioral/API regression.
   - For one-shot/manual mode, present numbered actionable items grouped by author type (Human first, Bot second), flag bot items with `[BOT: skeptical]`, include file/line and thread/comment id, then ask which to handle.

7. For each selected item:
   - Show relevant code context.
   - For bot items, state verdict first: valid, false positive, or partial.
   - Make the smallest correct change.
   - Add/update tests when needed.
   - If a comment calls for explanation rather than code, draft the response instead of forcing a code change.
   - Keep each change traceable to the thread/comment it addresses.

8. Summary.
   - Run `git status --short` and `git diff --stat`.
   - List addressed threads/comments, intentionally skipped items, tests/checks run, and any remaining ambiguity.

## Watch Loop

- Poll every 5 minutes (`sleep 300`) after each fetch/fix/check cycle.
- Continue until one of these happens:
  - `scripts/fetch_comments.py` reports `approval.has_thumbs_up: true` for a Codex/OpenAI/ChatGPT-like approval reaction.
  - There are no unresolved actionable comments and the user asked for one-shot mode.
  - `gh` auth/rate limits block progress.
  - A comment is ambiguous or risky enough to need user judgment.
- In each cycle:
  1. Fetch comments/reactions.
  2. Exit if a PR-level thumbs-up approval reaction is present.
  3. Filter resolved/outdated/noise comments.
  4. Apply all valid fixes automatically.
  5. Run the narrowest relevant checks.
  6. Summarize what changed, then wait 5 minutes and fetch again.

## Write Safety

- Do not reply on GitHub, resolve review threads, or submit a review unless the user explicitly asks.
- If comments conflict with each other or would cause a behavioral regression, surface the tradeoff before editing.
- If a comment is ambiguous, ask for clarification or draft a proposed response instead of guessing.
- If `gh` hits auth or rate-limit issues mid-run, ask the user to re-authenticate and retry.

## Fallback

If neither GraphQL nor flat `gh` reads can resolve the PR cleanly, say whether the blocker is missing repository scope, missing PR context, or CLI authentication. Then ask for the missing repo/PR identifier or a refreshed `gh auth login`.
