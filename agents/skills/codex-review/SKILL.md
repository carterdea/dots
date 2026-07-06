---
name: codex-review
description: Get a second opinion on code changes from OpenAI Codex CLI (gpt 5.5). Use before PRs or when you want an independent review from a different AI model.
---

# Codex Review

Get an independent code review from OpenAI Codex CLI as a second opinion or when a change is broad enough that another agent's perspective is useful.

## Workflow

1. Identify the review target: uncommitted changes, base branch, commit SHA, PR checkout, or specific files.
2. Create a temporary artifact directory for the Codex report.
3. Run `codex review` against the target, or with a focused prompt via stdin.
4. Read Codex's report and verify important claims against the code before presenting them.

A target selector (`--uncommitted` / `--base` / `--commit`) runs Codex's built-in review and **cannot be combined with a prompt** — Codex rejects `--base <BRANCH> [PROMPT]`. Use a selector for the standard review, or a stdin prompt (no selector) to steer the focus. Pick one shape:

```bash
ARTIFACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-review.XXXXXX")"
REPORT="$ARTIFACT_DIR/report.md"
PROMPT="$ARTIFACT_DIR/prompt.md"

# Standard review of a target (built-in prompt, no custom instructions):
# staged, unstaged, and untracked changes.
codex -C "$PWD" review --uncommitted > "$REPORT"
# current branch against a base branch.
codex -C "$PWD" review --base main > "$REPORT"
# a single commit.
codex -C "$PWD" review --commit <sha> > "$REPORT"

# Focused review: write instructions to "$PROMPT", then review the current
# uncommitted changes with them (no target selector allowed here).
codex -C "$PWD" review - < "$PROMPT" > "$REPORT"
```

If the diff is empty, tell the user there are no changes to review and stop.

## Review Prompt

For the focused (stdin) shape, ask Codex to use a code-review stance:

```text
Review these changes for bugs, regressions, missing tests, security issues, and requirement mismatches.

Prioritize findings over summary. For each finding include:
- severity
- file and line reference
- concrete failure mode
- suggested fix direction

Do not edit files. If there are no substantive findings, say so and name any residual test gaps.
```

If the user asked for a specific focus (security, tests, architecture, performance), use that as the prompt instead.

Add task-specific context when useful: requirements, risky areas, expected behavior, relevant tests, or files Claude is unsure about.

## Reporting back

Verify each finding against the cited code before relaying it, and separate confirmed issues from unverified Codex suggestions. Name the review target Codex inspected. If Codex finds nothing, say so clearly. If `codex` is not installed or the command fails, report the error and offer to review the changes directly instead.
