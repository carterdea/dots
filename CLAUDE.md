# CLAUDE.md

Organization-wide defaults. Project-specific CLAUDE.md files override these.

---

## Assistant Interaction

### ALWAYS

- ALWAYS use planning mode if a prompt ends with a question. Never make changes or propose to make changes if a prompt ends with a question.
- ALWAYS format code and commands in fenced blocks with language identifiers.
- ALWAYS use `[ ]` for open tasks and `[x]` for completed tasks in markdown checklists.
- ALWAYS give me prompts in markdown with block code sections escaped, when I ask for a prompt.
- ALWAYS use `python3` instead of `python`.

### NEVER

- NEVER use excessive emojis in documentation (a few for emphasis is acceptable).
- NEVER generate pseudocode unless explicitly requested.
- NEVER leave abandoned TODOs without context.

---

## Git Workflow

### ALWAYS

- Create descriptively named feature branches (e.g., `feature/cart-upsell`)
- Write clear, imperative commit messages (e.g., "Add cart upsell logic")
- Keep commits small and focused
- Run linting and tests locally before pushing
- Prefer squash-merge for linear history

### NEVER

- Force-push to shared branches
- Commit secrets, credentials, or large binaries
- Merge with unresolved conflicts

---

## Decision Making

- Prioritize best practices when confronted with difficult choices
- Research best practices when uncertain about implementation
- Specify which option is best practice when presenting choices
- Provide rationale for recommendations

---

## File Organization

- `README.md` — high-level overview, setup, quick-start
- `CLAUDE.md` — coding standards and assistant rules
- `PROJECT_NAME_PLAN.md` or `FEATURE_NAME_PLAN.md` — checklist for planned work
- `CHANGELOG.md` — chronological record of shipped changes
