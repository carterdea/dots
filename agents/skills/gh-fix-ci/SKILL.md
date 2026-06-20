---
name: gh-fix-ci
description: Watch a PR's CI checks and fix failures until every check is green
user-invocable: true
disable-model-invocation: true
---

# Fix CI

Watch the current branch's PR checks and iterate on failures until all required checks are green.

Use `gh pr checks` as the source of truth — it includes every PR-attached check, while `gh run list` only covers GitHub Actions.

## Steps

1. Resolve the PR for the current branch
```bash
gh pr view --json number,url,headRefName
```

2. Inspect the current check set
```bash
gh pr checks --json name,bucket,state,workflow,link
```
- If checks are still pending, watch them: `gh pr checks --watch --fail-fast`
- If all checks are already green, stop and report.

3. Diagnose the first failing check. Open its logs and focus on the root error
```bash
# when the failing check links to a GitHub Actions run
gh run view <run-id> --log-failed
```

4. Fix
- Prefer minimal, correct changes; scope each fix to a single failure cause
- Do not "fix" by skipping tests or bypassing hooks (`--no-verify`)
- If the failure is clearly unrelated to the PR and already fixed on main, merge latest main instead of bloating the PR
- If a failure looks flaky, retry once and note the flake evidence

5. Verify locally with the narrowest command that covers the failure, then push.

6. Re-check the full set — the check set can change between pushes
```bash
gh pr checks --json name,bucket,state,workflow,link
```
- Still failing: return to step 3 for the next failure
- All green: report and stop

## Output

- Current CI status
- Each failure and the fix applied (note any trade-offs or flakes)
- PR URL once all checks are green
