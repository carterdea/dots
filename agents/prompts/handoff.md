# Handoff

Generate a continuation prompt so the next session can pick up where this one left off.

## Steps

1. Review conversation history for the user's goal and any planning docs referenced.
   - If a planning doc was used, read it and note checked vs unchecked items.
   - If none was referenced, ask the user: "Was there a planning doc for this work?"

2. Gather git context
```bash
git branch --show-current
git status --short
git log --oneline -20
git diff --stat origin/$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)...HEAD 2>/dev/null
```

3. Output a single fenced markdown block the user can paste into a new session:

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

Pick up where the previous session left off. Start with [suggested next step].
```
````

4. Tell the user to copy the prompt and paste it into a new session.

## Rules

- Only reference real commits and changes; do not fabricate work.
- If no planning doc exists, say so; don't invent one.
- If no commits were made, note that work was exploratory/planning only.
- Include file paths so the next session can jump straight to relevant code.
