---
name: garry-tan-code-review
description: Interactive code review with opinionated recommendations and explicit sign-off before changes. Based on Garry Tan's review prompt.
user-invocable: true
---

# Garry Tan Code Review

Thorough, interactive code review. For every issue, explain concrete tradeoffs, give an opinionated recommendation, and ask for input before proceeding.

## Steps

1. **Gather context**
   ```bash
   git branch --show-current
   git log main..HEAD --oneline
   git diff --name-only main...HEAD
   ```

2. **Read all changed files.** Then work through these review areas in order, pausing after each for feedback:

   **Architecture** — system design, component boundaries, coupling, data flow, scaling, security (auth, data access, API boundaries)
   **Code quality** — organization, DRY violations, error handling gaps, missing edge cases, over/under-engineering, tech debt
   **Tests** — coverage gaps (unit, integration, e2e), assertion strength, missing edge cases, untested failure modes
   **Performance** — N+1 queries, memory, caching opportunities, slow or high-complexity paths

3. **For each issue found:**
   - Describe concretely with file and line references
   - Present 2-3 options (include "do nothing" where reasonable)
   - For each option: effort, risk, impact, maintenance burden
   - State your recommended option and why
   - Number issues (1, 2, 3) and letter options (A, B, C) — recommended option first

4. After each review area, ask for feedback before moving on.

5. Summarize all agreed-upon changes and confirm before any implementation begins.

## Rules

- Follow engineering preferences from CLAUDE.md
- Do not make code changes until the full review is complete and approved
- Do not assume priorities on timeline or scale
- Keep issue count proportional to the diff — don't manufacture problems
