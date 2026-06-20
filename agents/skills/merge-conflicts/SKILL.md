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

4. If there are merge conflicts, work one file at a time:
- List conflicted files: `git diff --name-only --diff-filter=U`
- Read each conflicted file fully (1500+ lines) to understand both sides
- **Understand the intent of each side.** Read the commit messages, and check the PR / issue / ticket behind each change, so you know *why* each side changed — not just what the text says
- **Resolve each hunk preserving both intents where possible.** Where the two sides are incompatible, pick the one matching the goal of the branch being rebased and note the trade-off in your report. Do not invent new behaviour. Rule of thumb: take incoming (main) for dependency/config changes, take ours (feature) for new feature code
- After resolving each file: `git add <file>`
- Continue: `git rebase --continue` — repeat until the rebase completes
- If a conflict is genuinely ambiguous, stop and ask before resolving

5. Run the project's automated checks to catch anything the merge broke. Discover them from the repo (package.json scripts, Makefile, etc.) and run in order: typecheck → tests → format/lint. Fix only what the merge broke.

6. Force-push the rebased branch
```bash
git push --force-with-lease origin HEAD
```

7. Report
- Which branch was rebased onto which
- How many conflicts were resolved, which files, and how (note any trade-offs)
- Result of the automated checks

## Rules

- Never use `git rebase --abort` unless the user asks
- Never use `git push --force` — always `--force-with-lease`
- Never modify files beyond what is needed to resolve the conflict and fix what the merge broke
- If checks fail in a way you can't attribute to the merge, report it — do not silently fix unrelated code
