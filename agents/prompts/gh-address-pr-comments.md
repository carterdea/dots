# Address PR Comments

Resolve actionable review comments for a PR, one-by-one.

## Steps

1. Checkout PR
```bash
gh pr checkout {PR_NUMBER}
```

2. Fetch PR data + comments
```bash
gh pr view {PR_NUMBER} --json title,body,state,author,headRefName,baseRefName,url,reviews
gh api repos/{OWNER}/{REPO}/pulls/{PR_NUMBER}/comments
gh api repos/{OWNER}/{REPO}/issues/{PR_NUMBER}/comments
```

3. Present a numbered list of actionable items (prefer file+line refs). Ask user which to handle.

4. For each selected item:
- Show relevant code context
- Make the smallest correct change
- Add/update tests when needed

5. Summary
```bash
git status --short
git diff --stat
```
