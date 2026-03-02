---
name: qa
description: Verify completed work in the browser using QA notes from a plan file
user-invocable: true
disable-model-invocation: true
---

# QA

Verify completed work in the browser using QA notes from a plan file.

## Usage

/qa docs/my_feature_PLAN.md --url http://localhost:3000
/qa docs/my_feature_PLAN.md
/qa

## Steps

1. Find the plan (file path or conversation history). Scan for unchecked `- [ ] QA:` items. If none, stop.

2. Detect the dev server URL (`--url`, or check common ports and project config). If nothing's running, ask.

3. List the QA items grouped by phase and confirm before starting.

4. Launch the browser with Playwright CLI:
   playwright-cli open <dev-server-url> --headed

   If auth is needed, check for cached state:
   playwright-cli state-load .playwright/.auth/qa-state.json

   If no cached state exists, ask the user for credentials, log in via CLI commands, then persist:
   playwright-cli state-save .playwright/.auth/qa-state.json

   If Playwright CLI can't complete auth (MFA, CAPTCHA, OAuth), fall back to Chrome MCP and have the user log in manually.

5. For each `- [ ] QA:` item:
   - Read the instruction and relevant source code
   - Navigate and interact using Playwright CLI commands (goto, click, fill, snapshot, etc.)
   - Take a snapshot to inspect page state
   - Screenshot the result and save to qa/
   - Pass: check it off `- [x] QA:`
   - Fail: leave unchecked, add a `> FAIL:` annotation describing what went wrong
   - Continue to next item regardless of pass/fail

6. Close the browser session when finished.

7. Summarize: passed, failed, skipped. If all passed, suggest `/pre-pr`. If any failed, suggest re-running `/execute-plan` to fix them.

## Rules

- Only verify -- never fix code
- Update the plan file after each item, not in batches
- Never store credentials in the plan file or reports
- Add `.playwright/.auth/` to `.gitignore` when creating auth state
- Prefer `snapshot` over `screenshot` for page inspection -- snapshots are token-efficient and provide element references for subsequent commands
