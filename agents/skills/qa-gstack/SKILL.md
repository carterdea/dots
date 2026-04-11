---
name: qa-gstack
description: |
  Systematically QA test a web application and fix bugs found. Runs browser-based QA
  testing, then iteratively fixes bugs in source code, committing each fix atomically
  and re-verifying. Three tiers: Quick (critical/high only), Standard (+ medium),
  Exhaustive (+ cosmetic). Produces before/after health scores, fix evidence, and a
  ship-readiness summary. For report-only mode, use /qa-gstack-only.
  Use when asked to "qa", "test this site", "find bugs", "test and fix", or
  "fix what's broken".
user-invocable: true
---

# /qa-gstack: Test -> Fix -> Verify

You are a QA engineer AND a bug-fix engineer. Test web applications like a real user -- click everything, fill every form, check every state. When you find bugs, fix them in source code with atomic commits, then re-verify. Produce a structured report with before/after evidence.

## Browser Tool Selection

**Default to `agent-browser` CLI.** Before using any browser tool, detect what's available:

```bash
command -v agent-browser 2>/dev/null && echo "FOUND:agent-browser" || echo "MISSING:agent-browser"
```

**Priority order:**
1. **agent-browser** (preferred) -- use `agent-browser open`, `agent-browser snapshot -i`, `agent-browser click`, `agent-browser fill`, `agent-browser screenshot`, etc. Invoke the `/agent-browser` skill for full command reference.
2. **Playwright CLI** (fallback) -- use if agent-browser is not installed
3. **Chrome MCP** (last resort) -- only if neither CLI tool is available

Do NOT use Chrome MCP (mcp__claude-in-chrome__*) when agent-browser is installed. All browser commands in this skill (navigate, screenshot, snapshot, click, fill) should use agent-browser equivalents.

## Setup

**Parse the user's request for these parameters:**

| Parameter | Default | Override example |
|-----------|---------|-----------------:|
| Target URL | (auto-detect or required) | `https://myapp.com`, `http://localhost:3000` |
| Tier | Standard | `--quick`, `--exhaustive` |
| Mode | full | `--regression baseline.json` |
| Output dir | `.qa-reports/` | `Output to /tmp/qa` |
| Scope | Full app (or diff-scoped) | `Focus on the billing page` |
| Auth | None | `Sign in to user@example.com`, `Import cookies from cookies.json` |

**Tiers determine which issues get fixed:**
- **Quick:** Fix critical + high severity only
- **Standard:** + medium severity (default)
- **Exhaustive:** + low/cosmetic severity

**If no URL is given and you're on a feature branch:** Automatically enter **diff-aware mode** (see Modes below).

**Check for clean working tree:**

```bash
git status --porcelain
```

If the output is non-empty (working tree is dirty), **STOP** and ask:

"Your working tree has uncommitted changes. /qa-gstack needs a clean tree so each bug fix gets its own atomic commit."

- A) Commit my changes -- commit all current changes with a descriptive message, then start QA
- B) Stash my changes -- stash, run QA, pop the stash after
- C) Abort -- I'll clean up manually

After the user chooses, execute their choice, then continue with setup.

**Check test framework (bootstrap if needed):**

Detect existing test framework and project runtime:

```bash
ls jest.config.* vitest.config.* playwright.config.* .rspec pytest.ini pyproject.toml phpunit.xml 2>/dev/null
ls -d test/ tests/ spec/ __tests__/ cypress/ e2e/ 2>/dev/null
```

If test framework detected: note conventions for regression test generation later. If none detected, offer to bootstrap one (vitest for Node/TS, pytest for Python, minitest for Ruby, etc.).

**Create output directories:**

```bash
mkdir -p .qa-reports/screenshots
```

---

## Modes

### Diff-aware (automatic when on a feature branch with no URL)

This is the **primary mode** for developers verifying their work. When the user says `/qa-gstack` without a URL and the repo is on a feature branch, automatically:

1. **Analyze the branch diff** to understand what changed:
   ```bash
   git diff main...HEAD --name-only
   git log main..HEAD --oneline
   ```

2. **Identify affected pages/routes** from the changed files:
   - Controller/route files -> which URL paths they serve
   - View/template/component files -> which pages render them
   - Model/service files -> which pages use those models
   - CSS/style files -> which pages include those stylesheets
   - API endpoints -> test them directly
   - Static pages (markdown, HTML) -> navigate to them directly

   **If no obvious pages/routes are identified from the diff:** Do not skip browser testing. Fall back to Quick mode -- navigate to the homepage, follow the top 5 navigation targets, check console for errors, and test any interactive elements found.

3. **Detect the running app** -- check common local dev ports:
   ```bash
   curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null
   curl -s -o /dev/null -w "%{http_code}" http://localhost:4000 2>/dev/null
   curl -s -o /dev/null -w "%{http_code}" http://localhost:5173 2>/dev/null
   curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null
   ```
   If no local app is found, ask the user for the URL.

4. **Test each affected page/route** with screenshots and console checks.

5. **Cross-reference with commit messages and PR description** to understand *intent* -- what should the change do? Verify it actually does that.

6. **Report findings** scoped to the branch changes.

### Full (default when URL is provided)
Systematic exploration. Visit every reachable page. Document 5-10 well-evidenced issues. Produce health score.

### Quick (`--quick`)
30-second smoke test. Visit homepage + top 5 navigation targets. Check: page loads? Console errors? Broken links? Produce health score.

### Regression (`--regression <baseline>`)
Run full mode, then load `baseline.json` from a previous run. Diff: which issues are fixed? Which are new? What's the score delta?

---

## Workflow

### Phase 1: Initialize

1. Create output directories
2. Start timer for duration tracking

### Phase 2: Authenticate (if needed)

If the user specified auth credentials, navigate to login page, fill credentials, submit. If 2FA/OTP is required, ask the user for the code. If CAPTCHA blocks, tell the user to complete it manually.

**NEVER include real passwords in the report.** Always write `[REDACTED]`.

### Phase 3: Orient

Get a map of the application:
- Navigate to target URL
- Take initial screenshot
- Map navigation structure (links, nav elements)
- Check console for errors on landing

**Detect framework** (note in report metadata):
- `__next` in HTML or `_next/data` requests -> Next.js
- `csrf-token` meta tag -> Rails
- `wp-content` in URLs -> WordPress
- Client-side routing with no page reloads -> SPA

### Phase 4: Explore

Visit pages systematically. At each page:
1. Take annotated screenshot
2. Check console for errors
3. Follow per-page exploration checklist:
   - **Visual scan** -- layout issues
   - **Interactive elements** -- click buttons, links, controls
   - **Forms** -- fill and submit. Test empty, invalid, edge cases
   - **Navigation** -- check all paths in and out
   - **States** -- empty state, loading, error, overflow
   - **Console** -- any new JS errors after interactions?
   - **Responsiveness** -- check mobile viewport if relevant

**Depth judgment:** Spend more time on core features (homepage, dashboard, checkout, search) and less on secondary pages.

### Phase 5: Document

Document each issue **immediately when found** -- don't batch them.

**Interactive bugs** (broken flows, dead buttons, form failures):
1. Screenshot before the action
2. Perform the action
3. Screenshot showing the result
4. Write repro steps referencing screenshots

**Static bugs** (typos, layout issues, missing images):
1. Single annotated screenshot showing the problem
2. Describe what's wrong

### Phase 6: Wrap Up

1. **Compute health score** using the rubric below
2. **Write "Top 3 Things to Fix"** -- the 3 highest-severity issues
3. **Write console health summary**
4. **Update severity counts** in the summary table
5. **Fill in report metadata** -- date, duration, pages visited, screenshot count, framework
6. **Save baseline** -- write `baseline.json` for future regression runs

---

## Health Score Rubric

Compute each category score (0-100), then take the weighted average.

### Console (weight: 15%)
- 0 errors -> 100
- 1-3 errors -> 70
- 4-10 errors -> 40
- 10+ errors -> 10

### Links (weight: 10%)
- 0 broken -> 100
- Each broken link -> -15 (minimum 0)

### Per-Category Scoring (Visual, Functional, UX, Content, Performance, Accessibility)
Each category starts at 100. Deduct per finding:
- Critical issue -> -25
- High issue -> -15
- Medium issue -> -8
- Low issue -> -3
Minimum 0 per category.

### Weights
| Category | Weight |
|----------|--------|
| Console | 15% |
| Links | 10% |
| Visual | 10% |
| Functional | 20% |
| UX | 15% |
| Performance | 10% |
| Content | 5% |
| Accessibility | 15% |

### Final Score
`score = sum(category_score * weight)`

---

## Framework-Specific Guidance

### Next.js
- Check console for hydration errors (`Hydration failed`, `Text content did not match`)
- Monitor `_next/data` requests in network -- 404s indicate broken data fetching
- Test client-side navigation (click links, don't just navigate) -- catches routing issues
- Check for CLS on pages with dynamic content

### Rails
- Check for N+1 query warnings in console (if development mode)
- Verify CSRF token presence in forms
- Test Turbo/Stimulus integration
- Check for flash messages appearing and dismissing correctly

### WordPress
- Check for plugin conflicts (JS errors from different plugins)
- Verify admin bar visibility for logged-in users
- Test REST API endpoints (`/wp-json/`)
- Check for mixed content warnings

### General SPA (React, Vue, Angular)
- Check for stale state (navigate away and back -- does data refresh?)
- Test browser back/forward -- does the app handle history correctly?
- Check for memory leaks (monitor console after extended use)

---

## Phase 7: Triage

Sort all discovered issues by severity, then decide which to fix based on the selected tier:

- **Quick:** Fix critical + high only. Mark medium/low as "deferred."
- **Standard:** Fix critical + high + medium. Mark low as "deferred."
- **Exhaustive:** Fix all, including cosmetic/low severity.

Mark issues that cannot be fixed from source code (e.g., third-party widget bugs, infrastructure issues) as "deferred" regardless of tier.

---

## Phase 8: Fix Loop

For each fixable issue, in severity order:

### 8a. Locate source

Find the source file(s) responsible for the bug using Grep and Glob.

### 8b. Fix

- Read the source code, understand the context
- Make the **minimal fix** -- smallest change that resolves the issue
- Do NOT refactor surrounding code, add features, or "improve" unrelated things

### 8c. Commit

```bash
git add <only-changed-files>
git commit -m "fix(qa): ISSUE-NNN -- short description"
```

- One commit per fix. Never bundle multiple fixes.

### 8d. Re-test

- Navigate back to the affected page
- Take **before/after screenshot pair**
- Check console for errors
- Verify the change had the expected effect

### 8e. Classify

- **verified**: re-test confirms the fix works, no new errors introduced
- **best-effort**: fix applied but couldn't fully verify
- **reverted**: regression detected -> `git revert HEAD` -> mark issue as "deferred"

### 8e.5. Regression Test

Skip if: classification is not "verified", OR the fix is purely visual/CSS with no JS behavior, OR no test framework detected.

1. Study the project's existing test patterns (file naming, imports, assertion style)
2. Trace the bug's codepath, then write a regression test:
   - Set up the precondition that triggered the bug
   - Perform the action that exposed the bug
   - Assert the correct behavior (NOT "it renders" or "it doesn't throw")
   - Include attribution comment: `// Regression: ISSUE-NNN -- {what broke}`
3. Run only the new test file
4. Passes -> commit: `git commit -m "test(qa): regression test for ISSUE-NNN"`
5. Fails -> fix test once. Still failing -> delete test, defer.

### 8f. Self-Regulation (STOP AND EVALUATE)

Every 5 fixes (or after any revert), compute the WTF-likelihood:

```
WTF-LIKELIHOOD:
  Start at 0%
  Each revert:                +15%
  Each fix touching >3 files: +5%
  After fix 15:               +1% per additional fix
  All remaining Low severity: +10%
  Touching unrelated files:   +20%
```

**If WTF > 20%:** STOP immediately. Show the user what you've done so far. Ask whether to continue.

**Hard cap: 50 fixes.** After 50 fixes, stop regardless of remaining issues.

---

## Phase 9: Final QA

After all fixes are applied:

1. Re-run QA on all affected pages
2. Compute final health score
3. **If final score is WORSE than baseline:** WARN prominently -- something regressed

---

## Phase 10: Report

Write the report to `.qa-reports/qa-report-{domain}-{YYYY-MM-DD}.md`

**Per-issue additions:**
- Fix Status: verified / best-effort / reverted / deferred
- Commit SHA (if fixed)
- Files Changed (if fixed)
- Before/After screenshots (if fixed)

**Summary section:**
- Total issues found
- Fixes applied (verified: X, best-effort: Y, reverted: Z)
- Deferred issues
- Health score delta: baseline -> final

**PR Summary:** Include a one-line summary suitable for PR descriptions:
> "QA found N issues, fixed M, health score X -> Y."

---

## Phase 11: TODOS.md Update

If the repo has a `TODOS.md`:

1. **New deferred bugs** -> add as TODOs with severity, category, and repro steps
2. **Fixed bugs that were in TODOS.md** -> annotate with "Fixed by /qa-gstack on {branch}, {date}"

---

## Output Structure

```
.qa-reports/
  qa-report-{domain}-{YYYY-MM-DD}.md    # Structured report
  screenshots/
    initial.png                          # Landing page
    issue-001-step-1.png                 # Per-issue evidence
    issue-001-result.png
    issue-001-before.png                 # Before fix
    issue-001-after.png                  # After fix
    ...
  baseline.json                          # For regression mode
```

---

## Important Rules

1. **Repro is everything.** Every issue needs at least one screenshot. No exceptions.
2. **Verify before documenting.** Retry the issue once to confirm it's reproducible.
3. **Never include credentials.** Write `[REDACTED]` for passwords in repro steps.
4. **Write incrementally.** Append each issue to the report as you find it. Don't batch.
5. **Never read source code during QA phases.** Test as a user, not a developer.
6. **Check console after every interaction.** JS errors that don't surface visually are still bugs.
7. **Test like a user.** Use realistic data. Walk through complete workflows end-to-end.
8. **Depth over breadth.** 5-10 well-documented issues with evidence > 20 vague descriptions.
9. **Never delete output files.** Screenshots and reports accumulate -- that's intentional.
10. **Show screenshots to the user.** After taking screenshots, use the Read tool on the output files so the user can see them inline.
11. **Never refuse to use the browser.** When the user invokes /qa-gstack, they are requesting browser-based testing. Never suggest evals or unit tests as a substitute.
12. **Clean working tree required.** If dirty, offer commit/stash/abort before proceeding.
13. **One commit per fix.** Never bundle multiple fixes into one commit.
14. **Revert on regression.** If a fix makes things worse, `git revert HEAD` immediately.
15. **Self-regulate.** Follow the WTF-likelihood heuristic. When in doubt, stop and ask.
