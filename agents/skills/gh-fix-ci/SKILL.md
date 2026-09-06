---
name: gh-fix-ci
description: Fix failing PR checks and watch CI until green. Use when asked to repair CI or when another skill needs CI diagnosis and fixes.
user-invocable: true
---

# Fix CI

Watch the current branch's PR checks and iterate on failures until all required checks are green.

Default to standalone loop mode. In single-pass mode, inspect checks, handle at most one failing cause, and return without waiting for remote checks or starting another repair cycle. A pass may validate, commit, and push its fix; loop mode does not change shipping permission. Respect explicit read-only or no-push requests. Preserve retry history across calls so a new pass does not grant another flake retry.

Use `gh pr checks` as the source of truth — it includes every PR-attached check, while `gh run list` only covers GitHub Actions.

## Steps

1. Use the caller's PR and repository when supplied; otherwise resolve the current branch's PR. Confirm the head SHA and work on that PR branch, preserving unrelated changes.
```bash
gh pr view --json number,url,headRefName
```

2. Inspect the current check set
```bash
gh pr checks --json name,bucket,state,workflow,link
```
- Handle an available failure before waiting for other checks.
- If only pending checks remain, return pending in single-pass mode. In standalone mode, wait interruptibly or in intervals of at most 60 seconds, then inspect again.
- If all checks are already green, stop and report.
- An empty or unavailable check set is unknown, not green. Report it rather than claiming success.

3. Diagnose the first failing check. Open its logs and focus on the root error
```bash
# when the failing check links to a GitHub Actions run
gh run view <run-id> --log-failed
```

4. Fix
- Prefer minimal, correct changes; scope each fix to a single failure cause
- Do not "fix" by skipping tests or bypassing hooks (`--no-verify`)
- If the failure is clearly unrelated to the PR and already fixed on main, merge latest main instead of bloating the PR
- If a failure looks flaky, retry once and note the flake evidence. Return immediately in single-pass mode; in standalone mode, recheck the rerun without making a code change.
- If that retry also fails, report a blocker instead of retrying again. Keep the run/job identity in session state across passes.

5. Verify locally with the narrowest command that covers the failure, then commit and push when authorized. If validation fails, keep changes local and report the blocker. If a no-push request leaves the fix local, return with that limitation. In single-pass mode, return after the fix or rerun request; do not wait for its remote result.

6. In standalone mode, re-check the full set on the current head; a push invalidates the old check results.
```bash
gh pr checks --json name,bucket,state,workflow,link
```
- Still failing: return to step 3 for the next failure
- All green: report and stop

## Output

- PR and repository, inspected and resulting head SHAs
- Current CI status: green, failed, pending, or unknown; results from before a push are stale
- Each failure and the fix applied (note any trade-offs or flakes)
- Whether a fix was pushed or a rerun requested, retry history, and any blocker
