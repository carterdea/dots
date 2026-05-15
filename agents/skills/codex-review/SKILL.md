---
name: codex-review
description: Get a second opinion on code changes from OpenAI Codex CLI. Use before PRs or when you want an independent review from a different AI model.
---

# Codex Review

Get an independent code review from OpenAI Codex CLI as a second opinion.

## Process

### 1. Determine the diff

Detect whether you're on the default branch and select the right diff:

```bash
BRANCH=$(git branch --show-current)
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [ -z "$BASE_BRANCH" ]; then
  BASE_BRANCH=$(git remote show origin 2>/dev/null | sed -n '/HEAD branch/s/.*: //p')
fi
if [ -z "$BASE_BRANCH" ]; then
  case "$BRANCH" in
    main|master|trunk)
      BASE_BRANCH=$BRANCH
      ;;
  esac
fi
if [ -z "$BASE_BRANCH" ]; then
  for candidate in main master trunk; do
    if git show-ref --verify --quiet "refs/heads/$candidate"; then
      BASE_BRANCH=$candidate
      break
    fi
  done
fi
if [ -z "$BASE_BRANCH" ]; then
  echo "Unable to determine the repository default branch for review." >&2
  echo "Set an origin HEAD, check out a branch with an upstream, or review the working tree diff manually." >&2
  exit 1
fi

if [ "$BRANCH" = "$BASE_BRANCH" ] || [ "$BRANCH" = "master" ] || [ "$BRANCH" = "main" ]; then
  REVIEW_WORKTREE=true
else
  REVIEW_WORKTREE=false
fi
```

If the diff is empty, tell the user there are no changes to review and stop.

### 2. Call Codex CLI

If the user provided custom focus instructions (security, tests, architecture, performance, etc.), use those as the review prompt. Otherwise use the default comprehensive prompt below.

Pipe the diff into Codex in non-interactive mode:

```bash
{
  cat <<'EOF'
Review the code changes in this diff for quality, correctness, and adherence to best practices.

## Review Checklist

### 1. Architecture & Design
- Follows established patterns in the codebase
- No unnecessary complexity or over-engineering
- Proper separation of concerns
- No anti-patterns introduced
- Dependencies are properly managed

### 2. Technology-Specific Best Practices
Detect the stack from file extensions and apply the right idioms:
- Python: type hints, async/await patterns, error handling, dependency injection
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
- Comments explain "why" not "what"
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
For each issue:
1. File and line reference
2. Issue description
3. Severity (critical / warning / suggestion)
4. Recommended fix with code example

Summarize with: issues by severity, overall assessment, ready-to-merge verdict. Skip praise — only report problems.

Diff to review:
EOF
  if [ "$REVIEW_WORKTREE" = true ]; then
    git diff
    git diff --cached
  else
    git diff "${BASE_BRANCH}...HEAD"
  fi
} | codex exec --skip-git-repo-check --model gpt-5.4 --full-auto -
```

### 3. For large diffs

If the diff exceeds roughly 4000 lines, split by file:

```bash
if [ "$REVIEW_WORKTREE" = true ]; then
  { git diff --name-only; git diff --cached --name-only; } | sort -u | while IFS= read -r file; do
    [ -n "$file" ] || continue
    {
      printf 'Review this diff of %s for bugs, security issues, and code quality problems. Be specific and concise.\n\nDiff to review:\n' "$file"
      git diff -- "$file"
      git diff --cached -- "$file"
    } | codex exec --skip-git-repo-check --model gpt-5.4 --full-auto -
  done
else
  git diff "${BASE_BRANCH}...HEAD" --name-only | while IFS= read -r file; do
    [ -n "$file" ] || continue
    {
      printf 'Review this diff of %s for bugs, security issues, and code quality problems. Be specific and concise.\n\nDiff to review:\n' "$file"
      git diff "${BASE_BRANCH}...HEAD" -- "$file"
    } | codex exec --skip-git-repo-check --model gpt-5.4 --full-auto -
  done
fi
```

### 4. Fallback

If `codex exec` is unavailable, fall back to quiet mode:

```bash
if [ "$REVIEW_WORKTREE" = true ]; then
  { git diff; git diff --cached; } | codex -q "Review this code diff for bugs, security issues, performance problems, and missing tests. Be specific with file references."
else
  git diff "${BASE_BRANCH}...HEAD" | codex -q "Review this code diff for bugs, security issues, performance problems, and missing tests. Be specific with file references."
fi
```

### 5. Present findings

Return Codex's findings verbatim. Do not editorialize or filter the results. If Codex finds no issues, say so clearly.
