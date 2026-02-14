# Handoff

Generate a continuation prompt so the next session can pick up where this one left off.

## Steps

1. **Identify the original task**
   - Review conversation history for the user's initial request and goal.

2. **Find planning documents**
   - Search the repo for planning docs:
   ```bash
   find . -maxdepth 3 -name '*PLAN*' -o -name '*plan*' -o -name 'TODO*' -o -name 'CHANGELOG*' | head -20
   ```
   - Read any found plans and note checked vs unchecked items.

3. **Summarize work completed**
   - Check git for commits made this session:
   ```bash
   git log --oneline -20
   git diff --stat origin/$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)...HEAD 2>/dev/null
   ```
   - List key changes, decisions, and assumptions from the conversation.

4. **Identify remaining work**
   - Pull unchecked items from any planning docs.
   - Note any known blockers, open questions, or TODOs left in code.
   ```bash
   git diff HEAD --name-only | xargs grep -n 'TODO\|FIXME\|HACK\|XXX' 2>/dev/null || true
   ```

5. **Capture current state**
   ```bash
   git branch --show-current
   git status --short
   ```

6. **Generate the handoff prompt**
   - Output a single fenced markdown code block containing a prompt the user can paste into a new session.
   - The prompt should use this structure:

````
```markdown
## Context

I'm continuing work on: [task description]
Branch: `[branch-name]`
Repo: [repo path]

## Planning Documents

- [list any planning docs with paths, or "None created"]

## Completed

- [bulleted list of what was done]

## Remaining

- [ ] [unchecked items from plans or conversation]

## Key Decisions

- [any assumptions, trade-offs, or choices made]

## Current State

[git status summary, any failing tests, blockers]

## Instructions

Pick up where the previous session left off. Start with [suggested next step].
```
````

7. Tell the user to copy the prompt and paste it into a new session.

## Rules

- Do NOT fabricate work that wasn't done; only reference real commits and changes.
- Keep the prompt concise but complete enough for a cold start.
- If no planning docs exist, say so; don't invent them.
- If no commits were made, note that work was exploratory/planning only.
- Include file paths so the next session can jump straight to relevant code.

## Usage

```
/handoff
```
