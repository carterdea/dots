---
name: claude-review
description: Get a second opinion on code changes from Claude Code CLI. Use before PRs or when you want an independent review from a different AI model. Trigger when the user asks for a code review, second opinion, or says "claude review".
---

# Claude Code Review

Get an independent code review from Anthropic's Claude CLI as a second opinion.

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

Pipe the diff into Claude's non-interactive print mode:

```bash
eval "$DIFF_CMD" | claude -p --model sonnet "Review the code changes in this diff for quality, correctness, and adherence to best practices.

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

If the diff exceeds ~4000 lines, split by file:

```bash
for file in $(eval "$NAMES_CMD"); do
  echo "=== Reviewing: $file ==="
  eval "${FILE_DIFF_CMD//FILE/$file}" | claude -p --model sonnet "Review this diff of $file for bugs, security issues, and code quality problems. Be specific and concise."
done
```

### 4. Present findings

Return Claude's findings verbatim. Do not editorialize or filter the results — the point is to get a raw second opinion from a different model.
