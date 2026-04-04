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
  BASE_BRANCH=main
fi

if [ "$BRANCH" = "$BASE_BRANCH" ] || [ "$BRANCH" = "master" ] || [ "$BRANCH" = "main" ]; then
  REVIEW_WORKTREE=true
else
  REVIEW_WORKTREE=false
fi
```

If the diff is empty, tell the user there are no changes to review and stop.

### 2. Call Codex CLI

Pipe the diff into Codex in non-interactive mode:

```bash
{
  cat <<'EOF'
You are reviewing a code diff. Analyze it for:
1. Bugs and logic errors
2. Security vulnerabilities
3. Performance issues
4. Missing error handling
5. Test coverage gaps
6. Code style and readability concerns

Be specific: reference exact file paths and line contexts. Suggest fixes. Prioritize by severity (critical > warning > suggestion). Skip praise and only report problems.

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

If the user provided custom focus instructions such as security, tests, architecture, or performance, append those to the review prompt.

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
