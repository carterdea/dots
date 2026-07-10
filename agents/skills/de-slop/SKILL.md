---
name: de-slop
description: "De-slop AI-shaped backend/general code before a PR. Use after an agent or prototype pass to remove branch-introduced artifacts: duplicate helpers, fixture hacks, hard-coded data, defensive wrappers, type-suppression escape hatches, config/boolean soup, brittle tests, hallucinated APIs, or local-idiom drift."
---

# De-Slop

Before a PR, or after an agent/prototype pass, remove obvious AI artifacts and cleanup noise.

Check the diff against main and remove slop introduced in the branch. Preserve behavior, public APIs, and tests unless the user explicitly asks for a refactor.

## Checklist

- Delete pointless scratch markdown (NOTES/PLAN/IDEAS/TODO) unless it's real docs
- Delete debug leftovers added in the branch: `console.log`, `print`, `debugger`, `dbg!`, verbose temp logging (keep intentional structured logging)
- Delete commented-out code blocks; git history already keeps them
- Remove emoji and decorative Unicode from log messages, comments, error strings, and CLI output unless local style genuinely uses them
- Read adjacent handwritten code before judging style; match local module boundaries, errors, logging, tests, naming, and helpers
- Remove redundant comments, filler docstrings, pass-through wrappers, and comments inconsistent with local style
- Drop defensive checks, state flags, dead branches, broad exception wrappers, and try/catch blocks abnormal for trusted code paths
- Remove null/undefined guards and optional-chaining sprawl on values the types or call sites already guarantee — fix the type instead of guarding everywhere
- Remove hand-rolled runtime type guards (`isRecord`, `isObject`, `isDefined`, `x is T` predicates, `isinstance` ladders) that sniff shapes on internal paths; parse/validate once at the boundary so downstream code trusts the type
- Remove type-checker and linter escape hatches added in the branch: `as any`, `as unknown as T`, `@ts-ignore`, `@ts-nocheck`, undocumented `@ts-expect-error`, non-null `!` assertions, `# type: ignore`, `eslint-disable`, `noqa` — fix the underlying type issue
- Collapse duplicate helpers, shadow APIs, fixture-shaped branches, and one-off variants
- Parameterize repeated literals and environment assumptions only when they represent a real variation point
- Replace boolean mode arguments, option-map soup, and config bags with explicit/cohesive APIs
- Flatten deeply nested code with early returns
- Replace mock-heavy tests with real assertions where possible
- Check tests for behavior focus, not method mirroring or snapshot/mock-call-only coverage
- Remove fake/uncited metrics
- Verify new helpers, imports, packages, APIs, permissions, and defaults are real in this repo/dependency graph
- Check secrets, string-built queries/shell commands, path traversal, unsafe deserialization, SSRF-shaped fetches, missing auth, sensitive logs, swallowed errors, missing timeouts, unchecked returns, and check-then-act races
- Fix patterns inconsistent with the file and surrounding codebase

## Flow

1. Scope the diff.
   - Start with `git diff --check` and `git diff --stat`.
   - Inspect touched files. If there is no diff, use recently modified files.
   - Ask one narrow question only when scope is genuinely ambiguous.
2. Establish the local idiom.
   - Read nearby code before fixing.
   - Prefer existing utilities, dependency style, data shapes, and validation/error patterns.
3. Show a dry-run list of issues found (file + line) unless the caller asked you to apply fixes directly.
4. Ask what to fix (`1 3 4`, `1-5`, `all`, `none`) unless the caller delegated judgment.
5. Apply selected edits.
6. Run the narrowest useful checks for touched files.
7. Re-open the diff and confirm the cleanup did not change intended behavior.

For larger diffs, split the scan into passes: local idiom/reuse, cohesion/API shape, control flow/errors, and behavior tests/safety.

## Findings

For review-only asks, return only the top 5-8 findings and merge repeated symptoms under one root cause.

Use this shape:

- `Issue`
- `Evidence`
- `Class` (`P0`, `P1`, `P2`)
- `Why it matters`
- `Possible non-AI explanation`
- `Smallest fix`
- `Acceptance check`
- `Confidence` (`High`, `Medium`, `Low`)
- `File/line`

For implementation asks, patch the code directly, then summarize what was simplified, what was intentionally left alone, what validation ran, and any follow-up risks.

## Guardrails

- Treat "AI-looking" as a quality smell, not a provenance claim.
- Keep behavior unchanged unless fixing a clear bug.
- Prefer minimal, focused edits over broad rewrites.
- Prefer objective maintainability, correctness, and safety defects over style-only opinions.
- Prefer parameterized, modular, locally idiomatic code when it reduces real duplication or clarifies ownership.
- Do not widen APIs into mega-helpers, config bags, boolean-flag modes, or generic parameter soup just to reduce line count.
- Do not add speculative abstraction layers, broad framework wrappers, or one-off utility namespaces.
- Do not reformat unrelated files or chase broad style churn.
- Keep the final summary concise (1-3 sentences).
- Do not delete `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, or `docs/**` without explicit confirmation.

## Resource

- `references/sources.md`: source basis for code-smell, AI-generated-code, API-shape, test-focus, and security-review checks.
