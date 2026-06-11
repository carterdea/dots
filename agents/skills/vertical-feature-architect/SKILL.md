---
name: vertical-feature-architect
description: Add net-new product, workflow, platform, or developer-experience features as small vertical slices. Use this skill whenever the user asks to build a new feature, add a new page/route/API/workflow/job/eval/operator path, enrich an existing feature with a new user-visible capability, or plan feature architecture before coding. This skill maps the files to change or create, defines the authoritative contract, specifies tests, and gives a QA plan before treating the feature as done.
user-invocable: true
---

# Vertical Feature Architecture

Use this skill to add net-new capability without scattering partial code across a codebase. The goal is a small end-to-end feature slice with clear ownership, typed contracts, lifecycle behavior, observability where useful, focused tests, and an explicit QA path.

Do not mention this skill name, its origin, or any person in code comments, commit messages, PR descriptions, docs, or user-facing project text. Treat the skill name as an invocation label only.

## Core Principles

- Build a tracer bullet first: the smallest useful path that crosses the real boundary end to end.
- Find the owner before adding files. New code should attach to the subsystem that already owns the domain.
- Create a file map before editing: existing files to change, new files to create, tests to add, docs or QA notes to update.
- Extend the authoritative contract before rendering or consuming the new state.
- Keep UI, route, job, and workflow code thin; put domain decisions with the owning service, handler, serializer, schema, or primitive.
- Preserve default behavior explicitly. If the feature is opt-in, prove the unset path is unchanged.
- Make lifecycle behavior concrete: terminal states, polling bounds, retry windows, background job phases, empty states, fallback paths, and deletion paths.
- Add observability when the feature crosses async work, external systems, durable workflow steps, evals, or operator debugging paths.
- Test the behavior matrix, not just the happy path.
- QA the user/operator path in the smallest realistic environment available.
- Keep examples as examples. Extract the principle, then adapt to the current codebase.

## When to Use

- The user asks to build a new feature, page, route, endpoint, workflow action, background job, integration path, eval target, report, or developer tool.
- An existing surface needs a new capability that crosses backend, frontend, schema, workflow, or test boundaries.
- The feature needs lifecycle behavior such as pending/running/completed/error, polling, retries, deferral, approvals, or terminal states.
- The feature has operator concerns such as audit logs, provenance, commands, seeded fixtures, reproducible evals, or admin/debug screens.
- The user asks for architecture before implementation and wants to know which files should change or be created.

Do not use this for pure refactors where no new capability is added. Use a refactor-oriented skill instead.

## First Pass

1. Inspect branch and dirty state. Do not overwrite unrelated user changes.
2. Read local instructions and nearby architecture docs, context docs, ADRs, route docs, test helpers, and existing feature plans.
3. Locate the closest existing subsystem with `rg` and file listings:
   - routes/pages/screens
   - API controllers/routers
   - services/repositories/serializers
   - schemas/DTOs/types
   - jobs/workflows/handlers
   - hooks/state/polling utilities
   - audit/logging/provenance helpers
   - tests/e2e/fixtures/factories
4. Identify the authoritative source of each fact the feature needs:
   - database row
   - service response
   - integration payload
   - session/user identity
   - parser output
   - workflow state
   - eval fixture or dataset
5. Name the smallest observable feature outcome.

## File Map

Before editing, produce a concise file map. If implementation is straightforward, this can be a short note before edits. If the feature is large or risky, make it a checklist and update it as work progresses.

Use this shape:

- Existing files to change:
  - `path`: why it owns part of the feature
- New files to create:
  - `path`: why a new file is better than expanding an existing file
- Tests to add or update:
  - `path`: behavior covered
- QA/doc notes:
  - `path` or `none`: when a durable note is useful
- Files intentionally not touched:
  - `path`: why the nearby file is not the owner

Create a new file when the code has a distinct responsibility and would otherwise bloat a route, component, service, handler, or test file. Prefer changing an existing owner when the new behavior is a natural extension of that owner.

## Architecture Moves

### 1. Define the Contract First

Start with the boundary that makes the feature real.

Common contract owners:

- backend service serializer for API response shape
- schema/DTO/type module for route or client data
- workflow action input/output schema
- event payload for async jobs
- eval target registry entry
- command/script interface for operator workflows

Specify:

- fields added or changed
- null and empty behavior
- ordering
- computed fields
- permission and ownership scope
- backwards-compatible default behavior
- error shape

Do not make the UI infer facts that the service should serialize. Do not make callers submit trusted facts that the backend, workflow, parser, or integration should derive.

### 2. Build the Tracer Bullet

Implement the smallest vertical path that proves the feature architecture:

- data source or fixture
- service/controller/handler contract
- typed client/route boundary
- UI, workflow, command, or operator surface
- lifecycle/empty/error state
- focused test

The tracer bullet should be narrow but real. Avoid broad scaffolding that does not execute.

### 3. Put Lifecycle Near the Owner

Lifecycle logic belongs where the lifecycle is controlled.

Examples:

- polling hooks own revalidation cadence and visibility checks
- services own computed run duration, ordered messages, and terminal status serialization
- workflow handlers own durable sleep, retry, approval, timeout, and deferral steps
- eval runners own dataset reset, seed profile, provenance, and upload/run mode
- UI owns presentation of pending, empty, disabled, loading, and error states

Make terminal states explicit. Bound polling and temporary refresh windows. Preserve no-op behavior when config is missing.

### 4. Add Observability When Time Or Operators Are Involved

Add audit, provenance, logging, or run metadata when a feature crosses:

- background jobs
- durable workflow waits
- external systems
- approvals or human-in-the-loop
- evals and datasets
- generated files
- operator/debug screens

Capture facts that help someone reproduce or explain the run:

- triggering user or source
- timestamps and duration
- status and error
- external run id
- dataset or fixture hash
- seed profile or environment key names
- branch/commit/dirty state for evals

Keep observability structured and close to the boundary that emits it.

### 5. Keep Surfaces Thin

Thin surfaces orchestrate, validate, and render. They do not become second services.

Good signs:

- route loaders fetch existing contracts and pass typed data onward
- actions submit narrow intents
- components are split by visible responsibility
- hooks own lifecycle mechanics
- services serialize response shape from source facts
- tests assert behavior visible at the boundary

If a route, component, or handler starts accumulating domain rules, extract a neutral primitive or move the decision to the owning module.

## Test Plan

Before calling the feature done, specify the tests needed. Add the focused tests unless the user explicitly asked for planning only.

Use this matrix and choose the rows that apply:

- Contract tests:
  - response fields, null behavior, ordering, computed fields, permissions, and error shape
- Service/handler tests:
  - happy path, missing source data, unauthorized or wrong-owner data, default unchanged, external failure
- Lifecycle tests:
  - pending/running/completed/error, polling starts/stops, retry/timeout, no-op config, deferral/reentry
- UI/route tests:
  - loader/action calls, typed data rendering, empty state, error banner, disabled/submitting state, navigation links
- Integration tests:
  - real database or fixture path when trust boundaries, persistence, or serialization are the point
- E2E tests:
  - only when the feature crosses user-visible surfaces that unit tests cannot prove
- Eval/operator tests:
  - command works, target registry loads, provenance exists, fixture grounding passes, output artifact is reproducible
- Regression tests:
  - behavior that was easy to miss, fallback/default path, and existing path preservation

Prefer focused tests first. Then run the quiet broad checks the repo provides.

## QA Plan

Every net-new feature needs a short QA plan, even if automated tests cover most of it.

Include:

- entry point:
  - route, command, job trigger, workflow action, admin page, or test target
- setup:
  - seed data, env vars, user role, feature flag, external service, fixture, or dataset
- happy path:
  - shortest realistic path through the feature
- edge paths:
  - empty, missing config, unauthorized/wrong-owner, error, pending/running/terminal, retry/timeout
- visual/browser checks when UI exists:
  - desktop/mobile if layout can change, loading/error/empty states, disabled controls, navigation
- operator checks when relevant:
  - audit event, log line, provenance, generated artifact, external run id, command output
- rollback or cleanup:
  - data created, feature flags, temporary env, queued jobs, generated files

If a dev server or external service is unavailable, state exactly what was skipped and what command or URL should be used later.

## Implementation Workflow

1. State the feature outcome in one sentence.
2. Produce the file map.
3. Define the authoritative contract and default behavior.
4. Build the tracer bullet through the real stack.
5. Add lifecycle behavior where it belongs.
6. Add observability/provenance if the feature crosses async, external, or operator boundaries.
7. Add focused tests from the test matrix.
8. Run focused checks first.
9. Run the quiet broad checks available in the repo.
10. QA the user/operator path or document what blocked QA.
11. Report the contract, files changed/created, tests, QA, skipped checks, and remaining risks.

## Skill Output

When reporting back, include:

- feature outcome
- file map summary
- contract added or changed
- lifecycle/observability added
- tests written and checks run
- QA performed
- skipped checks with reasons
- remaining risks or follow-ups
- unresolved questions at the end, if any

For planning-only requests, output the same structure as a proposed plan and do not edit files.

## Review Checklist

- [ ] Did the work start from the existing subsystem owner?
- [ ] Was there a file map before edits?
- [ ] Are new files justified by distinct responsibility?
- [ ] Is the authoritative contract explicit and typed?
- [ ] Is default/unset behavior preserved and tested?
- [ ] Is lifecycle behavior bounded and owned?
- [ ] Are audit/provenance/logging concerns covered when time, async work, or operators are involved?
- [ ] Are tests focused on behavior at the boundary?
- [ ] Is there a practical QA path?
- [ ] Did the final explanation avoid naming this skill or any person in project artifacts?
