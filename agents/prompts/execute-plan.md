# Execute Plan

Work through a plan file task-by-task, checking off items as they complete.

## Usage

```bash
/execute-plan docs/my_feature_PLAN.md       # Execute from a plan file
/execute-plan                                # Look for a plan in conversation history
/execute-plan docs/plan.md --commit-per-task # Override default commit cadence
/execute-plan docs/plan.md --dry-run         # Preview what would happen without executing
```

## Workflow

### 1. Load Plan

- If a file path is given, read it
- If no path, look for an Implementation Plan in conversation history
- If neither found, stop and ask
- If some tasks are already checked, report resume point: "Resuming from Phase 2, Task 3 (5/12 tasks complete)"

### 2. Check for Blockers

- Scan `## Open Questions` for unchecked `- [ ]` items
- For each, attempt to resolve by reading the codebase, CLAUDE.md, or project context
- If resolved, check it off and state the answer: "Resolved: 'Which ORM?' — SQLAlchemy, based on existing models in `src/db/`"
- If unresolvable, list remaining open questions and ask: "Proceed anyway or resolve first?"

### 3. Detect Environment

Auto-detect validation and tooling — don't ask, just state:

- Scan for `package.json`, `pyproject.toml`, `Makefile`, `Cargo.toml`, etc.
- Identify test runner (`bun test`, `pytest`, `cargo test`, etc.)
- Identify linter (`eslint`, `ruff`, `clippy`, etc.)
- Identify package manager (`bun`, `uv`, `cargo`, etc.)
- State assumptions: "Using `bun test` for tests, `eslint` for lint, `bun` for dependencies."

### 4. Execute Tasks

Default commit cadence: **per-phase**. Override with `--commit-per-task` or `--commit-end-only`.

State the plan upfront: "Committing per-phase. Starting at Phase 1, Task 1. 12 tasks across 3 phases."

Find the next unchecked `- [ ]` task under `## Implementation Plan` and execute it. This includes failed QA items (`- [ ] QA:` with a `> FAIL:` annotation) — treat the failure annotation as the task description, fix the underlying code, then remove the `> FAIL:` line but leave the QA item unchecked for `/qa` to re-verify.

For each task:

1. Read the task description
2. Research the codebase as needed to understand context
3. Implement the change
4. Validate (run tests, lint)
5. Update the plan file: `- [ ]` becomes `- [x]`
6. Add a QA note as a nested item under the completed task (see QA Notes below)
7. If all tasks in a phase are checked, check off the phase heading too: `### - [x]`
8. Commit if cadence requires it (never `git add .` — stage files individually)
9. Move to the next unchecked task

State assumptions instead of asking. User can interrupt if they disagree.

#### QA Notes

After checking off each task, add a nested `QA:` line describing how to verify the change in a browser or via API. This gives `/qa` concrete instructions to follow later.

- **User-facing changes** — add an unchecked QA item:
  ```markdown
  - [x] Add upsell modal component
    - [ ] QA: Navigate to /cart with items, click "You might also like", verify modal opens with related products
  ```

- **API/backend changes** — describe the request to verify:
  ```markdown
  - [x] Create /cart/upsell API endpoint
    - [ ] QA: POST /api/cart/upsell with product_id, expect 200 with upsell suggestions
  ```

- **Internal/non-user-facing changes** — no checkbox, just a note:
  ```markdown
  - [x] Refactor utils
    - QA: N/A
  ```

Keep QA notes brief — one line, focused on what to do and what to expect. The `/qa` command will use these as its test instructions.

### 5. Failure Triage

**Simple failures** — handle autonomously:
- Test failures, lint errors, type errors
- Missing imports or syntax issues
- Installing dependencies mentioned in the plan
- Minor config adjustments needed for a task to work

Fix the issue, re-validate, and continue. If the fix doesn't work after one retry, escalate to catastrophic.

**Catastrophic failures** — stop and report:
- Missing services, infrastructure, or credentials
- Task description too vague to act on
- Architectural ambiguity requiring a design decision
- Repeated failure after retry
- Permission errors

Stop execution, report what failed and why, and wait for user input before continuing. Suggest running `/handoff` if the user wants to continue in a new session.

### 6. Close Out

When all tasks are checked off (or all tasks in a phase are checked off):
- Run a final validation (tests, lint)
- Report summary: tasks completed, commits made, any issues encountered
- Review the completed work and suggest potential improvements, follow-up tasks, or areas that could benefit from additional testing — but do not act on any of them without user approval
- Output a **Next Step** block (see below)

#### Next Step Block

Gather git context:

```bash
git branch --show-current
git worktree list
```

If unchecked `- [ ] QA:` items exist in the plan, output:

````
```
/qa <plan-file-path>

branch: <current-branch>
worktree: <worktree-path>  # omit if not in a worktree
```
````

If all QA items are already checked (or all were `QA: N/A`), output:

````
```
/pre-pr

branch: <current-branch>
worktree: <worktree-path>  # omit if not in a worktree
```
````

- `worktree` line — only include if the current directory is a git worktree (not the main working tree)
- Keep it copy-pastable with no extra commentary inside the block

## Rules

- Never skip a task silently — either complete it or stop and explain
- Always update the plan file after each task, not in batches
- Dependencies listed in the plan are pre-approved for installation
- Stage files individually, never `git add .`
- Keep changes scoped to what the task describes — don't gold-plate
- If the plan file doesn't exist at the given path, stop and ask
- State assumptions, don't ask — the user will interrupt if something is wrong

## Dry Run

With `--dry-run`, run steps 1–3 only (Load Plan, Check Blockers, Detect Environment) and report:
- Tasks remaining (with phase grouping)
- Open questions found
- Detected tooling
- Resume point if applicable

Do not execute any tasks or modify any files.
