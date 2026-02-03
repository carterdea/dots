---
name: prove-it-bug-fix
description: Reproduce bugs with a failing test before fixing
allowed-tools: Task, Bash, Read, Write, Edit, Grep, Glob
user-invocable: false
---

# Prove It Bug Fix

When given a bug or error report, reproduce it with a failing test before attempting a fix.

## When to use

- User reports a bug, error, or unexpected behavior
- Stack trace or error message is provided
- Something "doesn't work" or "broke"

## Test Level Hierarchy

Reproduce at the lowest level that can capture the bug:

1. **Unit test** - Pure logic bugs, isolated functions (lives next to the code)
2. **Integration test** - Component interactions, API boundaries (lives next to the code)
3. **E2E/UX spec test** - Full user flows, browser-dependent behavior (follow project conventions)

## Steps

1. **Reproduce with subagent**
   - Spawn a subagent (Task tool) to write a test that demonstrates the bug
   - The test MUST fail before any fix is attempted
   - If the test passes, the bug isn't properly reproduced—refine the test

2. **Fix**
   - Only after reproduction is confirmed, implement the fix
   - Keep the fix minimal and focused

3. **Confirm**
   - Run the test again—it must now pass
   - This proves the fix works

## Subagent Prompt Template

```
Write a test that reproduces this bug:

{bug_description}

Requirements:
- Choose the appropriate test level (unit/integration/e2e)
- The test MUST fail currently to prove the bug exists
- Name the test descriptively (e.g., `test_cart_total_excludes_deleted_items`)
- Place the test following project conventions

Run the test and confirm it fails before reporting back.
```

## If Reproduction Isn't Feasible

Some bugs are environment-specific or transient. If a test truly can't capture the bug:

1. Document why (e.g., "Race condition only occurs under load")
2. Add logging or assertions that would catch it if it recurs
3. Note this in the commit message

Never skip reproduction silently.
