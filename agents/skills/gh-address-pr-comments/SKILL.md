---
name: gh-address-pr-comments
description: Resolve actionable review comments for a PR one-by-one
user-invocable: true
disable-model-invocation: true
---

# Address PR Comments

Resolve actionable review comments for a PR, one-by-one.

## Steps

0. Resolve PR_NUMBER
- If user supplied a PR number/URL, use it.
- Otherwise look up the open PR for the current branch:
  `gh pr view --json number,state,headRefName -q 'select(.state=="OPEN") | .number'`
- If that returns nothing, try: `gh pr list --head "$(git branch --show-current)" --state open --json number -q '.[0].number'`
- Only ask user if both lookups fail or return multiple PRs.

1. Checkout PR
gh pr checkout {PR_NUMBER}

2. Fetch PR data + comments (include author + position info)
gh pr view {PR_NUMBER} --json title,body,state,author,headRefName,baseRefName,url,reviews
gh api repos/{OWNER}/{REPO}/pulls/{PR_NUMBER}/comments --jq '.[] | {id, path, line, position, body, user: .user.login, user_type: .user.type}'
gh api repos/{OWNER}/{REPO}/issues/{PR_NUMBER}/comments --jq '.[] | {id, body, user: .user.login, user_type: .user.type}'

3. Filter out noise before classifying. Skip entirely (do not list, do not act on):
- Outdated review comments: review comments where `position` is `null` (line no longer exists in diff — GitHub UI labels these "Outdated"). Issue comments don't have position; only applies to pulls/comments endpoint.
- Vercel bot comments (login matches `vercel[bot]`, `vercel-bot`, or body mentions Vercel preview/deployment status)
- Bare agent mentions: body is just `@claude`, `@codex`, or short variants like `@codex review`, `@claude please review`, `@claude take a look` (no actionable content beyond the tag). Heuristic: strip mentions + whitespace; if <= ~3 words remain and none describe a change, skip.
- Already addressed this session: comments whose requested change you already made earlier in this same session. Safe to skip — note them as "already addressed" in the final summary rather than re-applying or re-verifying.

4. Classify each comment by author:
- **Human** (`user_type == "User"`): trust default. Assume correct unless obviously wrong. Verify scope + intent, then apply.
- **Bot** (`user_type == "Bot"` OR login matches `cursor[bot]`, `chatgpt-codex-connector`, `claude[bot]`, `coderabbitai[bot]`, `github-actions[bot]`, `*-bot`, `*[bot]`): skeptical default. Bots hallucinate, flag non-issues, miss context. For each bot comment:
  - Read cited code + surrounding context before acting
  - Ask: is claim factually correct? Does fix improve code or just silence bot?
  - Reject if: false positive, stylistic noise, conflicts with project patterns, suggests broken refactor
  - If rejected, note reason in summary. Do not "address" via no-op reply commit.

5. Present numbered list grouped by author type (Human first, Bot second). Flag bot items with `[BOT: skeptical]`. Ask user which to handle.

6. For each selected item:
- Show relevant code context
- For bot items: state verdict (valid / false positive / partial) before coding
- Make smallest correct change
- Add/update tests when needed
- Skip silently-rejected bot items — list in final summary

7. Summary
git status --short
git diff --stat
