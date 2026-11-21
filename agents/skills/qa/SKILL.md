---
name: qa
description: Verify completed work in the browser using QA notes from a plan file
user-invocable: true
---

# QA

Verify completed work in the browser using QA notes from a plan file.

## Usage

/qa docs/my_feature_PLAN.md --url http://localhost:3000
/qa docs/my_feature_PLAN.md
/qa

## Browser selection

Follow the local `agent-browser` skill's browser selection rules. Prefer the current product's available built-in browser for interactive QA. Use Agent Browser for reproducible automation, recording, diagnostics, or missing native capabilities. Before the first CLI browser command, read `agent-browser skills get core`; load `agent-browser skills get core --ref commands` for accessibility and network diagnostics. Keep project-required checks and evidence; report unavailable capabilities.

## Steps

1. Find the plan (file path or conversation history). Scan for unchecked `- [ ] QA:` items. If none, stop.

2. Detect the dev server URL (`--url`, or `portless list` and project config). If nothing's running, ask.

3. List the QA items grouped by phase and confirm before starting.

4. Open the preview in the selected browser. When using Agent Browser, generate a session name with `agent-browser session id --scope worktree --prefix qa` and substitute it for `<session>` below:

   **agent-browser:**
   ```bash
   agent-browser --session <session> open <dev-server-url>
   agent-browser --session <session> snapshot -i
   ```

   Pass `--session <session>` on every Agent Browser command in this run. Shell exports may not survive between tool calls.

   **Playwright CLI (fallback):**
   ```bash
   playwright-cli open <dev-server-url> --headed
   ```

   If auth is needed, check for cached state:
   - agent-browser: `agent-browser --session <session> state load .playwright/.auth/qa-state.json`
   - playwright-cli: `playwright-cli state-load .playwright/.auth/qa-state.json`

   If no cached state exists, use the selected browser's login flow or ask for missing credentials. Persist state only when needed.

   For MFA, CAPTCHA, or OAuth that automation cannot complete, hand the selected browser's login flow to the user.

5. For each `- [ ] QA:` item:
   - Read the instruction and relevant source code
   - Navigate and interact using the selected browser tool
   - Take a snapshot to inspect page state (`agent-browser --session <session> snapshot -i` or equivalent; `snapshot -i --delta` after same-page interactions)
   - Screenshot the result and save to `qa/screenshots/` (the baseline gitignores that subdir)
   - Check console errors, failed requests, and accessibility on each touched page. Use the selected browser's diagnostics or supplement with Agent Browser. For CLI audits, run `agent-browser --session <session> a11y --tags wcag2a,wcag2aa`, scoped with `--selector` when possible. Compare against a base-branch preview to identify new violations and add a `> A11Y:` note. A11y notes don't fail the item unless it concerns accessibility. If a required diagnostic is unavailable, record the gap in the summary.
   - Pass: check it off `- [x] QA:`
   - Fail: leave unchecked, add a `> FAIL:` annotation describing what went wrong
   - Continue to next item regardless of pass/fail

6. Close only the browser session created for this run (`agent-browser --session <session> close` for the CLI).

7. Summarize: passed, failed, skipped. If all passed, suggest opening a PR. If any failed, suggest re-running `/execute-plan` to fix them.

## Rules

- Only verify -- never fix code
- Update the plan file after each item, not in batches
- Never store credentials in the plan file or reports
- Add `.playwright/.auth/` to `.gitignore` when creating auth state
- Prefer `snapshot` over `screenshot` for page inspection -- snapshots are token-efficient and provide element references for subsequent commands
