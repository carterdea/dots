---
name: de-slop
description: Remove AI artifacts and cleanup noise before a PR
user-invocable: true
---

# De-Slop

Before a PR, remove obvious AI artifacts and cleanup noise.

Check the diff against main and remove slop introduced in the branch.

## Checklist

- Delete pointless scratch markdown (NOTES/PLAN/IDEAS/TODO) unless it's real docs
- Remove redundant comments, filler docstrings, and comments inconsistent with local style
- Drop defensive checks or try/catch blocks abnormal for trusted code paths
- Remove casts to `any` used only to bypass type issues
- Flatten deeply nested code with early returns
- Replace mock-heavy tests with real assertions where possible
- Remove fake/uncited metrics
- Fix patterns inconsistent with the file and surrounding codebase

## Flow

1. Show a dry-run list of issues found (file + line).
2. Ask what to fix (`1 3 4`, `1-5`, `all`, `none`).
3. Apply selected edits and summarize.

## Guardrails

- Keep behavior unchanged unless fixing a clear bug.
- Prefer minimal, focused edits over broad rewrites.
- Keep the final summary concise (1-3 sentences).
- Do not delete `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, or `docs/**` without explicit confirmation.
