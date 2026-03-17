---
name: design-doc
description: >-
  Format implementation plans as structured design documents for technical review.
  Use when planning multi-step features, refactors, migrations, or architectural
  changes before coding. Produces a design doc with problem context, proposed solution,
  file map with verified line references, alternatives considered, and phased
  implementation tasks. Trigger on "plan this out", "write a design doc", "help me
  plan the approach", "think through the tradeoffs", or any request to reason about
  how to build something before building it.
user-invocable: true
---

# Design Doc Command

Format implementation plans as structured design documents for technical review and discussion.

## Usage

/design-doc                    # Start a new design doc
/design-doc "feature name"     # Start with a specific feature

## Workflow

### 1. Gather Context

Ask the user:
- What problem are you solving?
- What's the current state/pain points?
- Any constraints or requirements?

**Then do a lightweight codebase scan** to understand structure:
- Project layout, naming conventions, key directories
- The dependency chain (what imports what, what calls what)

This gives you enough context to draft the plan structure. The deep file-level research happens in step 3.

### 2. Generate Design Doc

Output the design doc using this exact structure:

---

# {Project Name} Design Doc

## Problem Context

Brief description of the problem or opportunity. Overview of the domain and pain points. What is the current solution? What are its shortcomings?

## Proposed Solution

High-level summary of the proposed solution:
- What it will do
- How it will be built
- What's different from current state
- Key advantages

## Goals and Non-Goals

### Goals

- Goal 1: expected impact
- Goal 2: expected impact
- Goal 3: expected impact

### Non-Goals

- Non-goal 1 (explain why out of scope)
- Non-goal 2

## Design

Overall summary of the design and major components.

[Include diagram if helpful - ASCII or mermaid]

### Key Components

Describe major request paths, data models, and architectural decisions.

Add subsections for each major component as needed:
- Component A
- Component B

### File Map

**Every design doc must include a file map.** This is the most actionable section -- it tells the executing agent exactly where to look. Built in step 3 using subagent research.

Existing files needing changes:
- `path/to/file.ts` (lines 12-45) -- what changes and why
- `path/to/file.test.ts` (lines 80-95) -- where new test cases go

New files:
- `path/to/new_file.ts` -- purpose, follows naming convention from `path/to/similar_file.ts`
- `path/to/new_dir/new_file.ts` (new directory) -- purpose

Config/schema/migration files:
- `path/to/config.json` (lines 5-8) -- what gets added or changed

Group by phase if the plan is large. Every entry must come from actual codebase research, not guesses.

## Alternatives Considered

| Alternative | Pros | Cons | Why Not Chosen |
|-------------|------|------|----------------|
| Option A | ... | ... | ... |
| Option B | ... | ... | ... |

## Open Questions

- [ ] Question 1
- [ ] Question 2

## Implementation Plan

Every task must reference the specific file(s) it touches. Use the file map above — don't leave the executing agent guessing.

### - [ ] Phase 1: Foundation
- [ ] Task 1 — `path/to/file.ts` (lines X-Y)
- [ ] Task 2 — create `path/to/new_file.ts`

### - [ ] Phase 2: Core Implementation
- [ ] Task 3 — `path/to/file.ts` (lines X-Y), `path/to/other.ts` (lines X-Y)
- [ ] Task 4 — create `path/to/new_file.ts`

### - [ ] Phase 3: Polish & Testing
- [ ] Write tests — `path/to/file.test.ts`
- [ ] Documentation

## Appendix (optional — skip if empty)

External links, research data, or large diagrams that would break flow in the Design section. Do not repeat file paths or line numbers already in the File Map.

---

### 3. Build the File Map

After drafting the Implementation Plan, systematically find every file that needs to be touched or created. Use subagents to search in parallel -- one per phase or logical grouping.

**Launch Explore subagents** (Agent tool with `subagent_type: "Explore"`), each with a focused query derived from the tasks:
- "Find the files that handle [feature area]. Return file paths and the specific line ranges where [change] would land."
- "What test files exist for [module]? Where would new tests be added?"
- "Does `path/to/suggested/dir/` exist? What naming conventions do sibling files use?"

Give each subagent enough context about *what* you're planning to change so it can identify the right lines, not just the right files.

**What to include in the file map:**
- **Existing files needing changes:** path, line range, and a brief note on what changes and why
- **Existing test files:** where new test cases would be added
- **Config files:** if any config, schema, or migration files need updating
- **New files:** intended path following project conventions. If the parent directory exists, just list the path. If it doesn't, annotate with `(new directory)`

**Validate directory existence** for every new file path. Run `ls` or use Glob to confirm parent directories exist before listing them in the map.

**After collecting subagent results:**
1. Assemble the `### File Map` section in the design doc
2. Cross-reference every task in the Implementation Plan -- each task must reference its file map entries
3. If a task has no file reference, either find the file or flag it as an open question

### 4. Offer to Save

After generating, ask the user:

> Want me to save this as a markdown file in `docs/`? (Recommended for larger efforts; skip for small tasks.)

If yes:
- Save to `docs/{PROJECT_NAME}_PLAN.md` (snake_case, lowercase)
- Create the `docs/` directory if it doesn't exist

### 5. Iterate

After generating (and optionally saving):
- Ask if any sections need expansion
- Clarify open questions
- Refine based on feedback

### 6. Next Step Block

Once the design doc is finalized and saved, output a **Next Step** block so the user can quickly kick off execution. Gather git context first:

git branch --show-current
git worktree list

Then output:

/execute-plan <plan-file-path>

branch: <current-branch>
worktree: <worktree-path>  # omit if not in a worktree

- `<plan-file-path>` -- the path where the doc was saved (e.g., `docs/cart_upsell_PLAN.md`)
- `worktree` line -- only include if the current directory is a git worktree (not the main working tree)
- Keep it copy-pastable with no extra commentary inside the block

## Rules

- Keep language concise, sacrifice grammar for brevity
- No fake case studies or made-up numbers
- Include realistic implementation phases
- Always include a testing phase
- List unresolved questions at the end
- Use tables for comparisons
- Include code snippets or diagrams where helpful
- **Every task in the Implementation Plan must reference specific files and line ranges** (for existing code) or suggest a file name following project conventions (for new code). A task without a file reference is incomplete.
- **Always explore the codebase before writing the doc.** The file map and line references must come from actual research, not guesses.

## Output Format

# {Project Name} Design Doc

[Full document as specified above]

---

Open questions to discuss:
1. ...
2. ...

Ready to refine any section or proceed to implementation?

[After finalization and save, output the Next Step block]
