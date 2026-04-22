---
name: gh-address-pr-comments
description: Resolve actionable review comments for a PR one-by-one
user-invocable: true
disable-model-invocation: true
---

# Address PR Comments

Resolve actionable review comments for a PR, one-by-one.

## Steps

1. Checkout PR
gh pr checkout {PR_NUMBER}

2. Fetch PR data + comments (include author info)
gh pr view {PR_NUMBER} --json title,body,state,author,headRefName,baseRefName,url,reviews
gh api repos/{OWNER}/{REPO}/pulls/{PR_NUMBER}/comments --jq '.[] | {id, path, line, body, user: .user.login, user_type: .user.type}'
gh api repos/{OWNER}/{REPO}/issues/{PR_NUMBER}/comments --jq '.[] | {id, body, user: .user.login, user_type: .user.type}'

3. Classify each comment by author:
- **Human** (`user_type == "User"`): trust default. Assume correct unless obviously wrong. Verify scope + intent, then apply.
- **Bot** (`user_type == "Bot"` OR login matches `cursor[bot]`, `chatgpt-codex-connector`, `claude[bot]`, `coderabbitai[bot]`, `github-actions[bot]`, `*-bot`, `*[bot]`): skeptical default. Bots hallucinate, flag non-issues, miss context. For each bot comment:
  - Read cited code + surrounding context before acting
  - Ask: is claim factually correct? Does fix improve code or just silence bot?
  - Reject if: false positive, stylistic noise, conflicts with project patterns, suggests broken refactor
  - If rejected, note reason in summary. Do not "address" via no-op reply commit.

4. Present numbered list grouped by author type (Human first, Bot second). Flag bot items with `[BOT: skeptical]`. Ask user which to handle.

5. For each selected item:
- Show relevant code context
- For bot items: state verdict (valid / false positive / partial) before coding
- Make smallest correct change
- Add/update tests when needed
- Skip silently-rejected bot items — list in final summary

6. Summary
git status --short
git diff --stat
