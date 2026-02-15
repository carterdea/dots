# QA

Verify completed work in the browser using QA notes from a plan file.

## Usage

```bash
/qa docs/my_feature_PLAN.md --url http://localhost:3000    # QA against a running app
/qa docs/my_feature_PLAN.md                                # Auto-detect dev server URL
/qa                                                        # Find plan in conversation history
/qa docs/plan.md --chrome                                  # Force Chrome MCP instead of Playwright
```

## Workflow

### 1. Load Plan

- If a file path is given, read it
- If no path, look for an Implementation Plan in conversation history
- If neither found, stop and ask
- Scan for unchecked `- [ ] QA:` items — these are the test instructions
- If no unchecked QA items found, report "Nothing to QA" and stop
- Skip any `- [x] QA: None` items (internal/non-user-facing tasks)

### 2. Detect App URL

If `--url` is provided, use it. Otherwise, auto-detect:

- Look for a running dev server: check common ports (3000, 4000, 5000, 8000, 8080)
- Check `package.json` for `dev` or `start` scripts to infer the port
- Check `Procfile`, `docker-compose.yml`, or `.env` for port configuration
- For Shopify themes, look for `shopify theme dev` output or `localhost:9292`

If no running server is detected, stop and ask: "No dev server found. Start one and re-run, or pass `--url`."

### 3. Choose Browser Tool

**Default: Playwright CLI** (isolated, reproducible, supports auth persistence).

Use Playwright MCP tools (`mcp__plugin_playwright_playwright__*`) as the primary browser automation. Fall back to Chrome MCP (`mcp__claude-in-chrome__*`) only when needed.

Decision flow:

1. Start with Playwright
2. If a page hits an auth wall, attempt to authenticate (see Handle Auth below)
3. If auth fails (MFA, CAPTCHA, complex OAuth), switch to Chrome MCP and tell the user: "Auth requires manual login. Switching to Chrome — log in and I'll continue QA from there."
4. If `--chrome` flag is passed, skip Playwright and use Chrome MCP from the start

### 4. Present QA Plan

List all unchecked QA items grouped by phase:

```
Found 4 QA items to verify at http://localhost:3000:

Browser: Playwright (auth state: none cached)

Phase 1: Foundation
  - QA: Navigate to /cart with items, verify modal opens with related products
  - QA: POST /api/cart/upsell with product_id, expect 200

Phase 2: Core Implementation
  - QA: Navigate to /checkout, verify upsell suggestions appear in sidebar
  - QA: Complete checkout flow, verify upsell analytics event fires

Proceed?
```

Wait for user confirmation before starting browser interactions.

### 5. Handle Auth

When Playwright encounters a login redirect or auth wall:

#### First attempt — use cached auth state

Check for `.playwright/.auth/qa-state.json` in the project root. If it exists, load it:

```
Found cached auth state. Loading session...
```

If the cached session is expired (page still redirects to login after loading state), delete the stale file and proceed to credential login.

#### Second attempt — ask for credentials

Ask the user in the chat:

```
Auth required for this page. What are the login credentials for the dev environment?

I'll save the session so you won't need to enter these again until it expires.
```

Once the user provides credentials:

1. Navigate to the login page
2. Fill in the credentials and submit
3. Wait for successful redirect (URL no longer contains `/login`, `/sign-in`, etc.)
4. Save the authenticated session:
   ```
   browser.contexts[0].storageState({ path: '.playwright/.auth/qa-state.json' })
   ```
5. Continue QA with the authenticated session

**Important:** Add `.playwright/.auth/` to `.gitignore` if not already present.

#### Third attempt — fall back to Chrome MCP

If login fails (MFA prompt, CAPTCHA, OAuth redirect to third-party, or credentials rejected after one retry):

1. Stop Playwright
2. Tell the user: "Playwright can't complete login (reason). Switching to Chrome — please log in to `{url}` in your browser, then confirm here."
3. Wait for user confirmation
4. Continue remaining QA items using Chrome MCP tools (`mcp__claude-in-chrome__*`)
5. Note the tool switch in the report

### 6. Execute QA

For each unchecked `- [ ] QA:` item:

1. Read the QA instruction
2. Read the relevant source code to understand what was built (routes, components, expected behavior)
3. Execute the described verification using the active browser tool:
   - **Browser-based QA**: Navigate, click, fill forms, verify visible outcomes
   - **API-based QA**: Use fetch/XHR from the browser console or Playwright's request API to verify responses
4. Take a screenshot at the verification point
5. Evaluate: did the feature work as described?

**On pass:**
- Check off the item: `- [ ] QA:` becomes `- [x] QA:`
- Save screenshot to `qa/` directory with a descriptive name
- Move to the next item

**On fail:**
- Leave the item unchecked
- Add a failure annotation indented under the QA item:
  ```markdown
  - [ ] QA: Navigate to /cart with items, verify modal opens with related products
    > FAIL: Modal did not appear after clicking "You might also like". Button exists but onClick handler has no effect. Screenshot: qa/upsell-modal-fail.png
  ```
- Save the failure screenshot
- Continue to the next QA item (don't stop on individual failures)

### 7. Report

After all QA items are attempted, output a summary:

```
## QA Report

Plan: docs/feature_PLAN.md
URL: http://localhost:3000
Browser: Playwright (auth: cached session)

### Results

- Passed: 3
- Failed: 1
- Skipped: 0

### Failures

1. **Add upsell modal component**
   QA: Navigate to /cart with items, verify modal opens with related products
   FAIL: Modal did not appear. Button exists but onClick has no effect.
   Screenshot: qa/upsell-modal-fail.png

### Screenshots

All screenshots saved to `qa/`.
```

If all items passed: "All QA checks passed. Ready for `/pre-pr`."

If any failed: "Fix the failures above and re-run `/qa` to verify."

## Rules

- Never skip a QA item silently — pass it, fail it, or mark it as skipped with a reason
- Always update the plan file after each QA item, not in batches
- Always take a screenshot at the verification point, pass or fail
- Do not attempt to fix code — only verify. If something fails, report it
- Create the `qa/` directory if it doesn't exist
- Keep browser interactions focused — don't explore beyond what the QA instruction describes
- State what you're doing before each browser action: "Navigating to /cart..." "Clicking 'Add to Cart'..." "Verifying modal appears..."
- Never store credentials in the plan file, screenshots, or reports
- Add `.playwright/.auth/` to `.gitignore` when creating the auth state file
- If neither Playwright nor Chrome MCP tools are available, stop and explain what's needed
