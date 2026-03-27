---
name: merge-conflicts
description: Rebase current branch onto main/master, resolve merge conflicts, and force-push
user-invocable: true
---

# Merge Conflicts

Rebase the current branch onto the default branch, resolve any merge conflicts, and push.

## Steps

1. Identify the default branch and current branch
```bash
git branch --show-current
```
```bash
git remote show origin | grep 'HEAD branch' | awk '{print $NF}'
```
- If on the default branch: stop — nothing to rebase.

2. Fetch latest and start rebase
```bash
git fetch origin
```
```bash
git rebase origin/<default-branch>
```

3. If rebase succeeds cleanly — skip to step 5.

4. If there are merge conflicts:
- Run `git diff --name-only --diff-filter=U` to list conflicted files
- Read each conflicted file fully (1500+ lines) to understand both sides
- Resolve conflicts by choosing the correct code — prefer incoming (main) for dependency/config changes, prefer ours (feature) for new feature code
- After resolving each file: `git add <file>`
- Continue: `git rebase --continue`
- Repeat until rebase completes
- If a conflict is ambiguous, stop and ask before resolving

5. Force-push the rebased branch
```bash
git push --force-with-lease origin HEAD
```

6. Report
- Which branch was rebased onto which
- How many conflicts were resolved (if any)
- Which files had conflicts and how they were resolved

## Rules

- Never use `git rebase --abort` unless the user asks
- Never use `git push --force` — always `--force-with-lease`
- Never modify files beyond what is needed to resolve the conflict
- If the rebase produces test failures, report them — do not silently fix unrelated code
