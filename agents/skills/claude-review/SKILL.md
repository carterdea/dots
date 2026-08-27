---
name: claude-review
description: Get a second opinion on code changes from Claude Code CLI. Use before PRs or when you want an independent review from a different AI model. Trigger when the user asks for a code review, second opinion, or says "claude review".
---

# Claude Code Review

Get an independent code review from Anthropic's Claude CLI as a second opinion.

## Model selection

Pass `--model` with an alias — aliases always resolve to the latest version of each model, so never pin dated model IDs:

- `sonnet` — Claude Sonnet (latest is v5, `claude-sonnet-5`). Default: fast and cheap, good enough for most reviews.
- `opus` — Claude Opus (latest is v5, `claude-opus-5`). Stronger reasoning for tricky or subtle diffs.
- `fable` — Claude Fable (`claude-fable-5`), Anthropic's most capable model. Premium tier, roughly 2x Opus pricing. See Reviewing with Fable below.

If the user names a model ("use fable", "review with opus"), use that. Otherwise default to `sonnet`. Never upgrade to `fable` on your own initiative — it is opt-in.

Non-interactive calls use print mode: `claude -p --model <alias> "<prompt>"` with the diff piped via stdin.

## Reviewing with Fable

Only reach for Fable when the user asks for it by name, asks for "the deepest review" or "the best model", or the diff is genuinely high-stakes: security-sensitive code, auth, payments, concurrency, migrations, or a large refactor. For everything else Sonnet or Opus is the right call.

Fable behaves differently enough from the Opus family that the default recipe in Process needs three changes.

### 1. Set effort explicitly

Fable accepts `--effort low|medium|high|xhigh|max`. Effort controls how deep it thinks and how many tokens it spends, and it matters more on Fable than on any earlier model:

```bash
claude -p --model fable --effort xhigh "<prompt>"
```

- `xhigh` — the default for a Fable review. Best quality-per-token for code work.
- `max` — only when correctness beats cost: security audits, release-blocking diffs, anything the user calls critical.
- `high` — a fast Fable pass on a small diff.
- Do not pass `--effort` for Sonnet or Opus reviews unless the user asks; the CLI default is already right.

### 2. Use the short prompt, not the checklist

The long checklist in step 2 is tuned for smaller models. Prescriptive, step-by-step prompts measurably *reduce* Fable's output quality — it does better when given the goal and the stakes and left to structure the review itself. For Fable, replace the checklist prompt with:

```bash
eval "$DIFF_CMD" | claude -p --model fable --effort xhigh "Review this diff as a senior engineer who owns this codebase. Find real defects: correctness bugs, security holes, data-loss or concurrency risks, broken error handling, missing test coverage on the paths that matter. Judge the design too — wrong abstraction, misplaced responsibility, complexity that will not survive the next change.

Cite file and line for every finding, rate it critical/warning/suggestion, and show the fix. Skip praise and skip style nits already handled by linters. If the diff is fine, say so in one line."
```

Keep any user-supplied focus instructions ("focus on the auth changes") — append them, do not pad them out with extra scaffolding.

### 3. Give it time, and do not split the diff

- **It runs long.** A single Fable review of a real diff can take many minutes. Give the Bash call a long timeout, and run it in the background for anything past a few hundred lines rather than letting the call get killed mid-review. Fast mode does not exist for Fable, so there is no way to speed this up.
- **Do not split by file.** Fable has a 1M context window; the ~4000-line split in step 3 exists for smaller context budgets. Splitting throws away the cross-file reasoning that is the entire reason to use Fable. Send the whole diff in one call.

### Other Fable specifics

- Thinking is always on and cannot be disabled. The raw chain of thought is never returned, so asking it to "show your reasoning" gets you a summary at best — ask for conclusions and evidence instead.
- Fable can decline a request outright (safety classifier refusal) instead of returning a review. If that happens, rerun on `opus` and tell the user; do not keep rephrasing the prompt.
- If the CLI errors that the model is unavailable, the account lacks Fable access. Fall back to `opus` and say so explicitly in the output.

## Process

### 1. Determine the diff

Detect whether you're on a feature branch or main and select the right diff:

```bash
BRANCH=$(git branch --show-current)
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  # On main — review working tree (staged + unstaged) changes
  DIFF_CMD="git diff && git diff --cached"
  NAMES_CMD="{ git diff --name-only; git diff --cached --name-only; } | sort -u"
  FILE_DIFF_CMD="git diff -- FILE && git diff --cached -- FILE"
else
  # Feature branch — review full branch diff against main
  DIFF_CMD="git diff main...HEAD"
  NAMES_CMD="git diff main...HEAD --name-only"
  FILE_DIFF_CMD="git diff main...HEAD -- FILE"
fi
```

If the diff is empty, tell the user there are no changes to review and stop.

### 2. Call Claude CLI

If the user provided custom focus instructions (e.g., "focus on security"), use those as the review prompt. Otherwise use the default comprehensive prompt below.

Set the model per the Model selection section, then pipe the diff into Claude's non-interactive print mode. If the model is `fable`, use the short prompt and effort flag from Reviewing with Fable instead of the checklist below:

```bash
MODEL=sonnet  # or opus per Model selection; fable has its own recipe above
eval "$DIFF_CMD" | claude -p --model "$MODEL" "Review the code changes in this diff for quality, correctness, and adherence to best practices.

## Review Checklist

### 1. Architecture & Design
- Follows established patterns in the codebase
- No unnecessary complexity or over-engineering
- Proper separation of concerns
- No anti-patterns introduced
- Dependencies are properly managed

### 2. Technology-Specific Best Practices
Detect the stack from file extensions and apply the right idioms:
- Python: type hints, async/await, error handling, dependency injection
- Ruby/Rails: ActiveRecord patterns, service objects, controller actions, migrations
- TypeScript/React: component design, hooks usage, state management, type safety
- Node.js: async patterns, error handling, middleware design
- Go: error handling, goroutines, interfaces, package structure
- Rust: ownership, borrowing, error handling, trait usage
- Java/Spring: dependency injection, service layers, exception handling
- PHP/Laravel: Eloquent usage, middleware, validation, authorization

### 3. Code Quality
- Functions focused and reasonably sized
- Files organized and not too large
- No duplicated logic (DRY violations)
- Proper error handling (not silently swallowing errors)
- No security vulnerabilities (injection, XSS, CSRF, etc.)
- Tests cover critical paths and edge cases
- No hardcoded secrets or credentials

### 4. Consistency
- Follows project naming conventions
- Imports organized properly
- Code style matches existing codebase
- Comments explain 'why' not 'what'
- No commented-out code left behind

### 5. Performance
- No obvious issues (N+1 queries, unnecessary loops)
- Efficient data structures
- Proper caching where appropriate
- Database queries optimized

### 6. Testing
- Tests clear and focused
- Edge cases covered
- No flaky tests
- Test names describe what they test

## Output Format
For each issue: file/line reference, description, severity (critical/warning/suggestion), recommended fix with code example.

Summarize with: issues by severity, overall assessment, ready-to-merge verdict. Skip praise — only report problems."
```

### 3. For large diffs

If the diff exceeds ~4000 lines, split by file. Skip this entirely for `fable` — send the whole diff in one call:

```bash
for file in $(eval "$NAMES_CMD"); do
  echo "=== Reviewing: $file ==="
  eval "${FILE_DIFF_CMD//FILE/$file}" | claude -p --model "$MODEL" "Review this diff of $file for bugs, security issues, and code quality problems. Be specific and concise."
done
```

### 4. Present findings

Return Claude's findings verbatim. Do not editorialize or filter the results — the point is to get a raw second opinion from a different model.
