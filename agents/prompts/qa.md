# QA

Verify completed work in the browser using QA notes from a plan file.

## Usage

```bash
/qa docs/my_feature_PLAN.md --url http://localhost:3000
/qa docs/my_feature_PLAN.md
/qa
```

## Steps

1. Find the plan (file path or conversation history). Scan for unchecked `- [ ] QA:` items. If none, stop.

2. Detect the dev server URL (`--url`, or check common ports and project config). If nothing's running, ask.

3. List the QA items grouped by phase and confirm before starting.

4. Use Playwright MCP as the primary browser. If auth is needed, check for cached state in `.playwright/.auth/qa-state.json`, then ask the user for credentials if needed. Save the session with `storageState` for reuse. If Playwright can't auth (MFA, CAPTCHA, OAuth), fall back to Chrome MCP and have the user log in manually.

5. For each `- [ ] QA:` item:
   - Read the instruction and relevant source code
   - Execute the verification in the browser
   - Screenshot the result and save to `qa/`
   - Pass: check it off `- [x] QA:`
   - Fail: leave unchecked, add a `> FAIL:` annotation describing what went wrong and where (file, component, route). Be specific enough that `/execute-plan` can act on it as a task description
   - Continue to next item regardless of pass/fail

6. Summarize: passed, failed, skipped. If all passed, suggest `/pre-pr`. If any failed, suggest re-running `/execute-plan` to fix them.

## Rules

- Only verify — never fix code
- Update the plan file after each item, not in batches
- Never store credentials in the plan file or reports
- Add `.playwright/.auth/` to `.gitignore` when creating auth state
