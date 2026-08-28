---
name: no-comments
description: "Aggressively remove comments, docstrings, suppressions, and explanatory clutter that code can express better. Preserve only proven external constraints, required public documentation, and rationale that cannot be encoded."
disable-model-invocation: true
---

# No comments

Treat every comment as guilty until the surrounding code proves it earns its place. The goal is not literally zero comments. The goal is code that explains itself and a small residue of comments that preserve information the code cannot carry.

Follow the rubric directly. The workflow has no named-agent, slash-command, or external-skill dependencies.

## Scope

Use the files or diff named by the caller. Otherwise inspect the current diff against the base branch, defaulting to `main`, including staged and unstaged changes.

Stay inside that scope except for the smallest adjacent change required to remove a workaround safely. Do not edit generated files, vendored code, dependencies, or unrelated comments.

Review comments and comment-shaped constructs:

- Line and block comments
- Docstrings and documentation comments
- Commented-out code
- TODO, FIXME, HACK, NOTE, IMPORTANT, and warning banners
- Linter, formatter, type-checker, coverage, and test suppressions
- Disabled code paths and dead parameters justified only by comments

## Review rubric

### Delete

Delete comments that:

- Restate names, types, control flow, or the next line of code
- Narrate implementation steps or organize a short file with decorative headings
- Explain a workaround that can be removed by using the real API or fixing the type
- Preserve dead code, old behavior, debugging notes, or version-control history
- Make vague claims such as `important`, `temporary`, `for safety`, or `do not remove` without a concrete external reason
- Apologize for complexity instead of removing it
- Describe what a test does rather than why the behavior matters
- Repeat information already enforced by a type, schema, assertion, test name, error, or public documentation
- Are stale, speculative, or impossible to verify from the repository

When deletion makes code unclear, improve the name, type, interface, control flow, or test instead of rewriting the comment.

### Keep

Keep a comment only when it carries information that cannot reasonably live in code:

- A required license, copyright, generated-file marker, or tool directive
- Public API documentation required by the language, framework, or published contract
- A concrete external constraint such as a vendor bug, protocol rule, platform quirk, legal requirement, or compatibility boundary
- Non-obvious correctness, security, concurrency, numerical, or performance rationale where a simpler implementation would look valid but be wrong
- An intentionally surprising decision whose rejected alternative is likely to be reintroduced

A kept constraint should name the reason precisely. Add or preserve a stable issue, specification, or upstream reference when one exists. Do not invent citations.

### Fix, then delete

Comments often expose a code problem. Prefer the smallest root-cause fix:

- Rename an unclear symbol
- Extract a focused function or constant
- Replace a boolean mode or magic value with a meaningful type
- Delete a dead path or unused parameter
- Use the supported API instead of a workaround
- Encode an invariant in a type, parser, assertion, focused test, or lint rule
- Fix the underlying type or control flow before removing a suppression

Do not change product behavior merely to eliminate a comment. If the root cause is outside scope or the safe fix is non-trivial, keep the necessary comment and report the blocker.

### Shape check

When a root-cause fix changes an interface, type, module boundary, data flow, or multiple callers, sketch the shape before implementing:

1. Trace the current path and name the module that owns the behavior.
2. Write the intended caller usage first.
3. Sketch the smallest types, signatures, and module changes that support that usage. Do not add scaffolding or placeholder abstractions.
4. Compare the sketch with the simpler options: delete the dead path, rename the unclear symbol, use the supported API, or make a local control-flow fix.
5. Check every caller, default behavior, error path, and focused test the shape would affect.

Implement the sketch only when it remains a small, in-scope cleanup. If it reveals a new capability, migration, cross-module redesign, or behavior change, keep the necessary comment and report the proposed shape as separate follow-up work.

## Suppressions

Treat suppressions as executable exceptions, not prose:

- Audit `eslint-disable`, `biome-ignore`, `prettier-ignore`, `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `type: ignore`, `noqa`, coverage ignores, test skips, and equivalents.
- Remove the suppression by fixing the underlying issue when the scoped fix is safe.
- Preserve correctness or compatibility suppressions only when the tool is wrong or the constraint is external and proven.
- Never delete a suppression while leaving code that fails the corresponding check.
- Keep the narrowest possible suppression and require an exact reason when the syntax supports one.

## Workflow

1. Establish the base and list scoped files.
2. Read each scoped file and enough surrounding code to judge comments in context.
3. Classify each comment as `delete`, `keep`, `fix then delete`, or `blocked` using the rubric above.
4. Apply unambiguous deletions and the smallest safe root-cause fixes. Run the shape check for any fix that meets its trigger. Do not pause for approval unless a fix would change behavior, widen scope materially, or encode a disputed constraint.
5. Search the scope again for missed comments and suppressions.
6. Run the narrowest relevant formatter, lint, type, and test checks. Never claim a check passed unless it ran.
7. Re-read the diff to confirm the cleanup preserved behavior and did not remove required documentation or directives.

## Report

Return:

- Account for every scoped comment and suppression, with totals for deleted, kept, fixed then deleted, and blocked
- Root-cause fixes made
- Comments kept, with one-line reasons
- Blocked or unenforced constraints
- Checks run and their results

If nothing should change, say so. Do not manufacture cleanup to justify the pass.
