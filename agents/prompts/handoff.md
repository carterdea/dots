# Handoff

Generate a continuation prompt so the next session can pick up where this one left off.

## Usage

```bash
/handoff
```

## Workflow

### 1. Review Context

- Scan conversation history for the user's goal and any planning docs referenced.
- If a planning doc was used, read it and note checked vs unchecked items.
- If none was referenced, ask: "Was there a planning doc for this work?"

### 2. Detect Pipeline Position

Scan conversation for which commands were used (`/design-doc`, `/execute-plan`, `/qa`, `/de-slop`, `/pre-pr`). Read the plan file (if one exists) and classify its state:

| Plan state | Suggested next step |
|---|---|
| All implementation tasks unchecked | `/execute-plan <plan-path>` |
| Some tasks checked, some unchecked | `/execute-plan <plan-path>` (resume) |
| All tasks checked, unchecked `- [ ] QA:` items | `/qa <plan-path> [--url <dev-server-url>]` |
| All QA items checked | `/de-slop` → `code-simplifier` → `/pre-pr` |
| No plan file | `/design-doc` if the goal is clear |

If mid-execution: count checked vs total tasks, note the first unchecked (e.g., "Paused at Phase 2, Task 3 — 5/12 complete"). `/execute-plan` handles resuming.

### 3. Gather Git Context

```bash
git branch --show-current
git status --short
git log --oneline -20
git diff --stat origin/$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)...HEAD 2>/dev/null
```

### 4. Generate Handoff Prompt

Output a single fenced markdown block the user can paste into a new session. Use the template in **Output Format** below.

### 5. Deliver

Tell the user to copy the prompt and paste it into a new session.

## Rules

- Only reference real commits and changes; do not fabricate work.
- If no planning doc exists, say so; don't invent one.
- If no commits were made, note that work was exploratory/planning only.
- Include file paths so the next session can jump straight to relevant code.
- Suggested command must include all necessary args (plan path, dev server URL if detected).
- Never suggest a pipeline step already completed unless it needs re-running.

## Output Format

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

[Pipeline-aware instruction, e.g.:]
[- "Design doc complete. All implementation tasks unchecked — start execution."]
[- "Execution paused at Phase 2, Task 3 (5/12 complete). Resume execution."]
[- "All implementation tasks checked. QA items remain — run QA."]
[- "QA complete. Run de-slop, then code-simplifier, then pre-pr."]

## Suggested Next Step

Run: `[copy-pastable command with args]`
```
````
