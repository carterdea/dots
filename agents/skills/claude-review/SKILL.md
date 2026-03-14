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

Pipe the diff into Claude's non-interactive print mode:

```bash
eval "$DIFF_CMD" | claude -p --model sonnet "You are reviewing a code diff. Analyze it for:
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
for file in $(eval "$NAMES_CMD"); do
  echo "=== Reviewing: $file ==="
  eval "${FILE_DIFF_CMD//FILE/$file}" | claude -p --model sonnet "Review this diff of $file for bugs, security issues, and code quality problems. Be specific and concise."
done
```

### 4. Present findings

Return Claude's findings verbatim. Do not editorialize or filter the results — the point is to get a raw second opinion from a different model.
