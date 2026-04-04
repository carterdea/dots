---
name: codex-review
description: Get a second opinion on code changes from OpenAI Codex CLI. Use before PRs or when you want an independent review from a different AI model.
---

# Codex Review

Get an independent code review from OpenAI Codex CLI as a second opinion.

## Process

### 1. Determine the diff

Detect whether you're on a feature branch or `main` and select the right diff:

```bash
BRANCH=$(git branch --show-current)
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  DIFF_CMD="git diff && git diff --cached"
  NAMES_CMD="{ git diff --name-only; git diff --cached --name-only; } | sort -u"
  FILE_DIFF_CMD="git diff -- FILE && git diff --cached -- FILE"
else
  DIFF_CMD="git diff main...HEAD"
  NAMES_CMD="git diff main...HEAD --name-only"
  FILE_DIFF_CMD="git diff main...HEAD -- FILE"
fi
```

If the diff is empty, tell the user there are no changes to review and stop.

### 2. Call Codex CLI

Pipe the diff into Codex in non-interactive mode:

```bash
eval "$DIFF_CMD" | codex exec --skip-git-repo-check --model gpt-5.4 --full-auto "You are reviewing a code diff. Analyze it for:
1. Bugs and logic errors
2. Security vulnerabilities
3. Performance issues
4. Missing error handling
5. Test coverage gaps
6. Code style and readability concerns

Be specific: reference exact file paths and line contexts. Suggest fixes. Prioritize by severity (critical > warning > suggestion). Skip praise and only report problems."
```

If the user provided custom focus instructions such as security, tests, architecture, or performance, append those to the review prompt.

### 3. For large diffs

If the diff exceeds roughly 4000 lines, split by file:

```bash
for file in $(eval "$NAMES_CMD"); do
  eval "${FILE_DIFF_CMD//FILE/$file}" | codex exec --skip-git-repo-check --model gpt-5.4 --full-auto "Review this diff of $file for bugs, security issues, and code quality problems. Be specific and concise."
done
```

### 4. Fallback

If `codex exec` is unavailable, fall back to quiet mode:

```bash
eval "$DIFF_CMD" | codex -q "Review this code diff for bugs, security issues, performance problems, and missing tests. Be specific with file references."
```

### 5. Present findings

Return Codex's findings verbatim. Do not editorialize or filter the results. If Codex finds no issues, say so clearly.
