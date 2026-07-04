---
name: coobeyon-refactor
description: Refactor codebases by collapsing orchestration, tightening typed boundaries, deleting broad context leakage, and adding ratchet tests. Use when the user wants to clean up architecture, simplify a workflow of routers/agents/handlers passing shared state, migrate a boundary, replace broad context objects with typed ownership, remove stale compatibility layers, or make agent/application code easier to reason about while preserving behavior.
user-invocable: true
---

# Refactor Cleanup Architecture

Use this skill when the user wants to clean up a codebase, simplify architecture, migrate a boundary, remove stale layers, or make agent/application code easier to reason about. The goal is not cosmetic refactoring. The goal is to make ownership, trust, data flow, and test surfaces explicit.

Do not mention this skill name, its origin, or any person in code comments, commit messages, PR descriptions, docs, or user-facing project text. Treat the skill name as an invocation label only.

## Core Principles

- Collapse orchestration before extracting more abstractions.
- Replace pass-through layers and broad context with owned typed boundaries.
- Treat caller-provided parameters, loader defaults, and UI state as request data, not authority.
- Derive trusted facts from authoritative product, database, session, parser, or integration data.
- Keep separate identities separate when runtime reconciliation and persistence need different ids.
- Extract neutral domain primitives when behavior appears in multiple surfaces.
- Serialize API contracts, computed fields, null behavior, and ordering at service boundaries.
- Make lifecycle behavior explicit: bounded polling, terminal states, fallbacks, and deletion paths.
- Make invariants executable through tests, inventory checks, eval metadata, and short invariant notes.
- Refactor in small ratcheted migrations after any large simplification.
- Keep examples as examples. Extract the principle, then adapt to the current codebase.

## When to Use

- A workflow has many routers, agents, services, pipelines, handlers, or strategy maps passing the same state around.
- Authorization, tenancy, identity, tool access, or data scope is passed through layers as a broad context object.
- A feature has compatibility fallbacks, transition helpers, or old names that keep reappearing.
- Tests mostly verify implementation details instead of boundary behavior.
- An eval, fixture, or integration suite is flaky because the setup does not reflect the real product data path.
- The user asks to clean up architecture while preserving behavior.

## First Pass

1. Inspect the current branch and dirty state.
2. Read nearby architecture docs, ADRs, context docs, eval docs, and test helpers when present.
3. Identify the real boundary:
   - trust boundary
   - integration boundary
   - API boundary
   - tool boundary
   - workflow boundary
   - storage boundary
4. Name the invariant that should hold at that boundary.
5. Find the old concepts that violate the invariant.
6. Use `rg` to inventory those concepts across production code and tests.

## Refactoring Moves

### 1. Collapse Orchestration

Look for chains where each layer mostly delegates to the next layer. Prefer one narrow runtime loop or coordinator that calls owned capability modules.

Signals:

- many modules named like router, manager, pipeline, strategy, generic agent, adapter, processor, or handler
- repeated state mutation across layers
- behavior spread across prompts, strategy maps, and formatter glue
- tests that need to mock many layers to verify one user path

Move toward:

- one obvious entrypoint
- bounded capabilities
- small helper modules with domain ownership
- result normalization at the edge

### 2. Replace Broad Context With Owned Boundaries

Find objects that carry too many unrelated facts through too many layers. These usually hide ownership, make callers accidentally powerful, and blur the difference between request data and trusted facts.

Common smells:

- auth context passed into tools
- tenant/user/session/company data forwarded into unrelated modules
- request objects reused as authorization facts
- tool params carrying role, permissions, scope, or trusted ids
- optional compatibility fields accepted deep inside production paths
- loader defaults submitted back as saved state
- display fallbacks used as persisted values
- cached or caller-provided data overriding fresh parsed, fetched, or database data

Move toward:

- identity/session input for identity boundaries
- capability data for already-authorized surfaces
- explicit params for filters, target names, operation choices, and output shape
- product/database/session/parser/integration lookup for trusted facts
- explicit precedence rules when fallback data and authoritative data can both exist
- tests for the failure path that introduced the fallback

### 3. Put Decisions With Their Owner

Do not leave policy decisions, shared domain rules, or response shaping in orchestration code.

Examples of ownership:

- authorization decisions live in authorization modules or tool server modules
- route/tool defaults live in bounded parameter modules
- shared formatting, schedule, date, status, lifecycle, parse, normalize, and describe rules live in neutral domain primitive modules
- API response shape lives in service serializers or boundary modules
- computed fields, null behavior, and ordered collections are serialized next to their source facts
- answer formatting lives in result formatter modules
- fixture grounding lives in eval setup or fixture resolvers
- inventory allowlists live in guard tests

When two surfaces share behavior, extract the domain rule into a neutral module instead of letting one surface import from the other. Keep the primitive free of route, component, framework, and product-flow assumptions unless those assumptions are the domain.

### 4. Delete Bypass Paths

After introducing the new boundary, remove or quarantine old fallback paths. Make lifecycle behavior explicit instead of leaving permanent compatibility paths or timers.

Look for:

- raw context fallback flags
- legacy token helpers
- old parameter names accepted alongside new ones
- direct dispatch paths that bypass the new policy
- permanent polling loops that should stop on terminal states
- optimistic ids overwritten by persisted ids during async acknowledgement
- tests that prove the old path still works

Move toward:

- explicit, scoped, tested fallbacks tracked for deletion
- polling only for active statuses or short post-action windows
- visibility and idle-state checks before revalidation
- stable runtime/UI keys plus separate persisted ids for dedupe, lookup, and reconciliation

### 5. Add Ratchet Tests

Every cleanup should make regression difficult.

Useful ratchets:

- unit tests for new boundary behavior
- tests proving forbidden fields are stripped or rejected
- inventory tests that parse or search production files for old symbols
- eval metadata checks for expected tool, expected authorization, persona, and fixture grounding
- integration tests that exercise the real data path instead of mocked trust facts
- tests that prove async acknowledgements do not remount, duplicate, or lose user-visible state
- tests for when polling starts, continues, and stops

When an inventory allowlist exists, shrink it as migration work completes.

### 6. Leave Invariant Notes

When a fix depends on a non-obvious invariant, write a short note in the repo's existing documentation system.

Use this shape:

- concepts/search terms
- key files
- verification commands
- useful-when trigger
- invariant
- regression history
- verification notes

The note should make the next maintainer find the rule before they rediscover the bug.

## Workflow

1. State the invariant.
2. Inventory current violations with `rg`.
3. Choose the smallest boundary slice that can be migrated end to end.
4. Add or update tests that define the desired boundary behavior.
5. Introduce exact typed inputs and outputs.
6. Move decision logic to the owning module.
7. Update callers to use the new boundary.
8. Remove bypasses for that slice.
9. Shrink inventory allowlists or add a new guard.
10. Run focused checks, then the quiet broad checks available in the repo.

## Skill Output

When reporting back, include:

- invariant changed or protected
- old surface removed or narrowed
- new boundary shape
- tests/guards added
- remaining migration surface, if any
- unresolved questions at the end, if any

Do not describe the work as copying a person. Describe the architectural principle and the local codebase effect.

## Review Checklist

- [ ] Did orchestration get simpler?
- [ ] Did any pass-through layer remain without earning its interface?
- [ ] Are trusted facts derived by the owner, not accepted from callers?
- [ ] Did broad context shrink into exact boundary data?
- [ ] Are old fallbacks removed or tracked?
- [ ] Are forbidden fields guarded by tests?
- [ ] Did tests cover the boundary instead of only implementation details?
- [ ] Did the final explanation avoid naming this skill or any person in project artifacts?
