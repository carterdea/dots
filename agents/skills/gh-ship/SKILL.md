---
name: gh-ship
description: Commit, push, and file a concise pull request in one step, or file one for a branch already committed. Use when the user asks to ship or open a PR; `babysit-pr` takes it from there.
user-invocable: true
---

# Ship

Commit, push, and file a concise PR in one step.

Read if present: `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`. Their branch naming, commit conventions, and required checks govern every step below, so read them before the first write, not after the push.

## Steps

1. Safety check
git branch --show-current
- If on `main`/`master`: stop and create a branch: `git checkout -b feat/short-desc`

2. Inspect changes
git status --porcelain
git diff --stat
BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
git fetch origin "$BASE"
git log --oneline "origin/$BASE..HEAD"
- Fetch first or `origin/$BASE` may be days stale, which reads base commits as branch work
- If the tree is clean but the branch has commits ahead of the base, skip to step 4 — this is the "just open the PR" case
- If there are no changes and no commits ahead, stop

3. Stage + commit
git add path/to/file1 path/to/file2
git commit -m "type(scope): short description"
- Never `git add .`
- One commit unless changes are clearly separate concerns

4. Push
git push -u origin $(git branch --show-current)

5. File the PR — see below. If one already exists, report its URL instead.

## Filing

Before filing, check whether a PR for this branch already exists. Review the diff locally against `origin/$BASE` to make sure its contents match the goal.

PR titles usually become commit messages, so follow the repository's title conventions. Look at recently merged PRs and Git history for examples. Prefer a concise, human-readable title that explains why the change matters:

BAD
> perf(server): negotiate permessage-deflate on the websocket

GOOD
> perf(server): cut websocket frame size by 70%+ with gzipping

Open the description with a simple explanation of the problem based on Carter's original prompt, then briefly explain the solution. Do not lead with an implementation inventory:

BAD
> Removed implicit workspace carry-over from every "new thread" entry point (cmd+n / cmd+shift+o, sidebar v1/v2 buttons, command palette). New threads inherit only the project from context; branch, worktree, and env mode always come from the configured defaults. Deleted buildContextualThreadOptions, startNewThreadInProjectFromContext, and the v1 sidebar's seed-context machinery.

GOOD
> My "new worktree" default was ignored when starting new threads on existing worktrees. Super unintuitive. Now your preferences always apply.

Open a real PR rather than a draft so review bots run:

```bash
gh pr create --title "type(scope): why the change matters" --body "..."
```

If Carter also asked to babysit it, continue with the `babysit-pr` skill.
