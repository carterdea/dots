# Failing checks

`gh pr checks NUMBER` covers external providers as well as GitHub Actions. Diagnose the failed check on the current head; old runs do not describe the current code.

For Actions, fetch the failed job directly even while other jobs run:

```bash
gh api --paginate repos/OWNER/REPO/actions/runs/RUN_ID/jobs --jq '.jobs[] | select(.conclusion=="failure") | {id, name}'
gh api repos/OWNER/REPO/actions/jobs/JOB_ID/logs
```

Read an external provider's details URL or report that its logs are unavailable. Name the cause before changing code.

Fix repository failures, run the relevant local check, and push only passing changes. If validation remains red, keep changes local and report the failure.

For infrastructure failures such as registry 5xx errors or runner timeouts, rerun the failed run once with `gh run rerun RUN_ID --failed`. If it fails again, report the blocker. Never change code to appease an infrastructure flake. Fix pending review feedback first when that push will retrigger CI anyway.
