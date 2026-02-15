# Handoff

Generate a continuation prompt so the next session can pick up where this one left off.

## Steps

1. Review conversation history for the user's goal and any planning docs referenced.
   - If a planning doc was used, read it and note checked vs unchecked items.
   - If none was referenced, ask the user: "Was there a planning doc for this work?"

2. Detect pipeline position.

   Scan conversation history for which commands were used (`/design-doc`, `/execute-plan`, `/qa`, `/de-slop`, `/pre-pr`). Then read the plan file (if one exists) and classify its state:

   | Plan state | Meaning | Suggested next step |
   |---|---|---|
   | Plan exists, all implementation tasks unchecked | Design complete | `/execute-plan <plan-path>` |
   | Plan exists, some implementation tasks checked, some unchecked | Execution in progress | `/execute-plan <plan-path>` (resume) |
   | Plan exists, all implementation tasks checked, unchecked `- [ ] QA:` items exist | Execution complete | `/qa <plan-path>` (add `--url <dev-server-url>` if a dev server was detected during the session) |
   | Plan exists, all QA items checked | QA complete | `/de-slop`, then run `code-simplifier` agent, then `/pre-pr` |
   | No plan file | Design phase or exploratory | `/design-doc` if the goal is clear |

   **Mid-execution detail:** If `/execute-plan` was used but unchecked tasks remain, identify the resume point. Count checked vs total implementation tasks and note the first unchecked task (e.g., "Execution paused at Phase 2, Task 3 — 5/12 tasks complete"). `/execute-plan <plan-path>` already handles resuming.

3. Gather git context
```bash
git branch --show-current
git status --short
git log --oneline -20
git diff --stat origin/$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)...HEAD 2>/dev/null
```

4. Output a single fenced markdown block the user can paste into a new session:

````
```markdown
## Context

I'm continuing work on: [task description]
Branch: `[branch-name]`
Repo: [repo path]

## Planning Document

[path to planning doc, or "None created"]

## Completed

- [bulleted list of what was done]

## Remaining

- [ ] [unchecked items from plan or conversation]

## Key Decisions

- [assumptions, trade-offs, or choices made]

## Current State

[git status summary, any failing tests]

## Instructions

[Pipeline-aware instruction. Examples:]
[- "Design doc is complete. All implementation tasks are unchecked — start execution."]
[- "Execution paused at Phase 2, Task 3 (5/12 tasks complete). Resume execution."]
[- "All implementation tasks are checked. QA items remain — run QA."]
[- "QA complete. Run de-slop, then code-simplifier, then pre-pr."]

## Suggested Next Step

Run: `[copy-pastable command with args, e.g. /execute-plan docs/feature_PLAN.md]`
```
````

5. Tell the user to copy the prompt and paste it into a new session.

## Rules

- Only reference real commits and changes; do not fabricate work.
- If no planning doc exists, say so; don't invent one.
- If no commits were made, note that work was exploratory/planning only.
- Include file paths so the next session can jump straight to relevant code.
- The `## Suggested Next Step` command must include all necessary args: plan file path, branch name (if useful for context), and dev server URL if one was detected during the session.
- Never suggest a pipeline step that was already completed unless it needs to be re-run.
