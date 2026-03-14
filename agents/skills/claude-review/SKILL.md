---
name: claude-review
description: Get a second opinion on code changes from Claude Code CLI. Use before PRs or when you want an independent review from a different AI model. Trigger when the user asks for a code review, second opinion, or says "claude review".
---

# Claude Code Review

Get an independent code review from Anthropic's Claude CLI as a second opinion.

## Process

### 1. Determine the diff

```bash
# Check if on a feature branch
BRANCH=$(git branch --show-current)
BASE="main"

if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  # Review working tree changes
  DIFF=$(git diff && git diff --cached)
else
  # Review full branch diff
  DIFF=$(git diff "$BASE"...HEAD)
fi
```

### 2. Call Claude CLI

Pipe the diff into Claude's non-interactive print mode:

```bash
git diff main...HEAD | claude -p --model sonnet "You are reviewing a code diff. Analyze it for:
1. Bugs and logic errors
2. Security vulnerabilities
3. Performance issues
4. Missing error handling
5. Test coverage gaps
6. Code style and readability concerns

Be specific: reference exact file paths and line contexts. Suggest fixes. Prioritize by severity (critical > warning > suggestion). Skip praise — only report problems."
```

If the user provided custom focus instructions (e.g., "focus on security"), append those to the prompt.

### 3. For large diffs

If the diff exceeds ~4000 lines, split by file:

```bash
for file in $(git diff main...HEAD --name-only); do
  echo "=== Reviewing: $file ==="
  git diff main...HEAD -- "$file" | claude -p --model sonnet "Review this diff of $file for bugs, security issues, and code quality problems. Be specific and concise."
done
```

### 4. Present findings

Return Claude's findings verbatim. Do not editorialize or filter the results — the point is to get a raw second opinion from a different model.
