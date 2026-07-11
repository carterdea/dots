---
name: refactor-campaigns
description: Refactor codebases by collapsing orchestration, tightening typed boundaries, deleting broad context leakage, and adding ratchet tests. Use when the user wants to clean up architecture, simplify a workflow of routers/agents/handlers passing shared state, stage a large architectural campaign or provider/vendor migration behind one capability surface, replace broad context objects with typed ownership, harden LLM tool boundaries, ground evals in fixtures, remove stale compatibility layers, or make agent/application code easier to reason about while preserving behavior.
user-invocable: true
---

# Refactor Cleanup Architecture

Use this skill when the user wants to clean up a codebase, simplify architecture, migrate a boundary, remove stale layers, or make agent/application code easier to reason about. The goal is not cosmetic refactoring. The goal is to make ownership, trust, data flow, and test surfaces explicit.

Do not mention this skill name, its origin, or any person in code comments, commit messages, PR descriptions, docs, or user-facing project text. Treat the skill name as an invocation label only.

## Core Principles

- Collapse orchestration before extracting more abstractions.
- Stage big changes as a campaign: collapse first, stabilize behavior, then ratchet quality with small guards.
- Cut migration seams at the incumbent's shape; document the target contract and the debt in the same change.
- Route cross-cutting choices (provider, vendor, tenant) through one registry keyed by trusted context, never by branching in callers.
- Replace pass-through layers and broad context with owned typed boundaries.
- Treat caller-provided parameters, loader defaults, and UI state as request data, not authority.
- Credentials and caller-visible schemas carry identity and business parameters, never authority; re-derive authority at point of use.
- Derive trusted facts from authoritative product, database, session, parser, or integration data.
- Fail closed with typed reasons when a capability is unsupported.
- Keep separate identities separate when runtime reconciliation and persistence need different ids.
- Extract neutral domain primitives when behavior appears in multiple surfaces.
- Serialize API contracts, computed fields, null behavior, and ordering at service boundaries.
- Make lifecycle behavior explicit: bounded polling, terminal states, fallbacks, and deletion paths.
- Split stable data from volatile data so refresh, pagination, and polling only touch what changed.
- Cache stable prefixes, not request-specific enrichment or authorization-sensitive context.
- Preserve absent, empty, null, and invalid as separate states at form and API boundaries.
- Make invariants executable through tests, inventory checks, eval metadata, and short invariant notes.
- Ground eval expectations in the fixtures the system actually runs against, with recorded provenance.
- Write the design, the rejected alternatives, and the open questions into the repo alongside the code.
- Refactor in small ratcheted migrations after any large simplification.
- Keep examples as examples. Extract the principle, then adapt to the current codebase.

## When to Use

- A workflow has many routers, agents, services, pipelines, handlers, or strategy maps passing the same state around.
- Authorization, tenancy, identity, tool access, or data scope is passed through layers as a broad context object.
- A second provider, vendor, or backend must plug in behind an existing capability surface.
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

## Big Change Campaigns

Large architectural improvements are staged, not landed whole. Two levels of sequencing:

Across PRs: **collapse → stabilize → ratchet**. The big simplification PR lands first (net-negative lines), behavior is stabilized on the smaller surface, then small surgical PRs pin behavior with deterministic guards. Cheap guards are only viable because the collapse made the surface small.

Within a big PR, commits land **feature last**, each standing on verified ground:

1. Boundary — the type/seam migration, behavior preserving.
2. Ground truth — deterministic fixtures the system will be judged against.
3. Harness — evals, provenance, dataset normalization.
4. Behavior — stabilization judged by steps 2–3.
5. Tooling — inventory ratchets, suppression-baseline burn-down, hooks.
6. Feature — the headline change, last and smallest.

After wiring a new seam, land a tests-only "prove the path" commit showing existing callers route through the new implementation end-to-end. Migrate in micro-slices, each pairing prod and test changes roughly 1:1. Expect most of the diff to be verification machinery.

For seam mechanics, cutover decisions, doc artifacts, product-contract versioning, and the PR verification protocol, read [references/big-change-playbook.md](references/big-change-playbook.md).

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

### 2. Cut Seams at the Incumbent's Shape

When migrating a boundary to support a new provider, vendor, or backend, create the seam as a behavior-preserving shim before moving any behavior.

Move toward:

- new interface types that alias or match the incumbent's shapes; consumers keep eating the field names they already eat
- an incumbent adapter that is a pure delegation shim: each method a one-line forward to the pre-existing function
- one registry that owns the routing choice, keyed by trusted context, with a single insertion point for future tenant-aware routing
- the richer target contract designed fully in the design doc but implemented minimally, with the debt and anti-drift rules written in the same commit
- unsupported capabilities failing closed with explicit typed errors, never partial or fake data

### 3. Replace Broad Context With Owned Boundaries

Find objects that carry too many unrelated facts through too many layers. These usually hide ownership, make callers accidentally powerful, and blur the difference between request data and trusted facts.

Common smells:

- auth context passed into tools
- tokens or credentials carrying role, permissions, scope, or authorized-id lists
- trust-related parameters visible in caller- or LLM-facing tool schemas
- tenant/user/session/company data forwarded into unrelated modules
- request objects reused as authorization facts
- tool params carrying role, permissions, scope, or trusted ids
- optional compatibility fields accepted deep inside production paths
- loader defaults submitted back as saved state
- display fallbacks used as persisted values
- cached or caller-provided data overriding fresh parsed, fetched, or database data

Move toward:

- identity-only tokens (who, tenant, session), with authority re-derived at point of use and session claims cross-checked against server-side state
- wrapper/impl splits at tool boundaries: the caller-visible signature holds only business parameters; infrastructure injects identity out of band
- trust-shaped parameters stripped at the client boundary, with tests pinning the stripping
- typed closed unions for denial reasons, not strings
- capability data for already-authorized surfaces
- explicit params for filters, target names, operation choices, and output shape
- product/database/session/parser/integration lookup for trusted facts
- derived minimal slices instead of raw blob dumps at model boundaries; "not available" answered from an authoritative listing
- explicit precedence rules when fallback data and authoritative data can both exist
- tests for the failure path that introduced the fallback

### 4. Put Decisions With Their Owner

Do not leave policy decisions, shared domain rules, or response shaping in orchestration code.

Examples of ownership:

- authorization decisions live in authorization modules or tool server modules
- provider/vendor/tenant selection lives in one registry, not in callers
- route/tool defaults live in bounded parameter modules
- shared formatting, schedule, date, status, lifecycle, parse, normalize, and describe rules live in neutral domain primitive modules
- API response shape lives in service serializers or boundary modules
- computed fields, null behavior, and ordered collections are serialized next to their source facts
- answer formatting lives in result formatter modules
- fixture grounding lives in eval setup or fixture resolvers
- inventory allowlists live in guard tests

When two surfaces share behavior, extract the domain rule into a neutral module instead of letting one surface import from the other. Keep the primitive free of route, component, framework, and product-flow assumptions unless those assumptions are the domain.

### 5. Delete Bypass Paths

After introducing the new boundary, remove or quarantine old fallback paths. Make lifecycle behavior explicit instead of leaving permanent compatibility paths or timers.

Look for:

- raw context fallback flags
- legacy token helpers
- old parameter names accepted alongside new ones
- direct dispatch paths that bypass the new policy
- permanent polling loops that should stop on terminal states
- optimistic ids overwritten by persisted ids during async acknowledgement
- tests that prove the old path still works
- suppression baselines (type-checker baselines, lint ignores) that let old debt hide

Move toward:

- explicit, scoped, tested fallbacks tracked for deletion
- blocked surfaces enforced at two layers (removed from the catalog and rejected at dispatch), each with tests
- suppression baselines drained to zero in the same change
- polling only for active statuses or short post-action windows
- visibility and idle-state checks before revalidation
- stable runtime/UI keys plus separate persisted ids for dedupe, lookup, and reconciliation

### 6. Split Stable And Volatile Data

When a route, loader, service, prompt, or agent context mixes long-lived metadata with frequently changing records, separate those fetch and computation boundaries.

Look for:

- pagination or load-more actions that refetch the whole parent page
- polling that reloads static metadata, tool definitions, permissions, or prompts
- prompt/context builders that recompute base templates and request-specific facts together
- cache keys that include user or request data only because stable and volatile inputs are bundled

Move toward:

- narrow child loaders or endpoints for volatile collections
- stable metadata loaded once at the parent boundary
- base prompt/model lookup separated from request-specific enrichment
- cache keys made from stable identity only, with explicit TTL, max entries, stats, and invalidation

Example:

```ts
// Before: pagination refetches metadata and the first page.
loadMoreFetcher.load(`/agents/${agent.id}?cursor=${cursor}`);

// After: pagination only fetches the volatile collection.
loadMoreFetcher.load(`/agents/${agent.id}/runs?cursor=${cursor}`);
```

### 7. Isolate Integration Dialects

When a provider, framework, or external API needs special wire shape, hide that dialect behind a small typed adapter. Keep provider checks out of orchestration code and business logic.

Look for:

- `if provider === ...` checks spread through callers
- provider-specific message blocks, cache hints, headers, retry flags, or response fields inline with domain logic
- tests that assert provider details through a large workflow

Move toward:

- one tiny adapter that accepts domain-shaped input and returns provider-shaped output
- direct unit tests for provider-specific serialization
- callers that only choose the adapter or pass a model/provider id

Example:

```ts
// Before: provider wire shape leaks into the caller.
messages.unshift({ role: 'system', content: systemPrompt });

// After: the adapter owns provider-specific message shape.
messages.unshift(buildStableSystemMessage(modelId, systemPrompt));
```

### 8. Preserve Boundary Intent

At form, API, and patch/update boundaries, do not collapse absent, empty, null, and invalid into the same value. Those states often mean different things.

Look for:

- optional field collectors that drop empty strings on update
- blank optional inputs that should clear persisted values but are ignored
- required fields where blank values slip into generic optional handling
- caller-provided organization, tenant, or ownership ids included in update payloads

Move toward:

- `undefined` for not submitted or unchanged
- `null` for explicit clear when the boundary supports clearing
- validation errors for blank required values
- trusted scope derived outside the submitted payload

Example:

```ts
// Before: empty optional fields disappear, so users cannot clear them.
const payload = collectOptionalFields(formData, fields);

// After: included empty optional fields become explicit clears.
const payload = {
  domain: formData.has('domain') ? getTrimmedValue(formData, 'domain') || null : undefined,
};
```

### 9. Warn, Block, Let the User Choose

When the system detects a probable user mistake, do not auto-correct silently and do not just warn. Block the default path and present two consequence-named actions: the recommended fix (a real state transition, not a relabel) and a deliberate override. Detection may warn; only the user decides — treat silent auto-correction as a bug. Keep the detection heuristic dumb and inspectable.

For unsafe machine-proposed operations (for example a model tool call missing a dry-run flag), rewrite the call to the safe form instead of denying, and pin the rewrite with a test.

### 10. Add Ratchet Tests

Every cleanup should make regression difficult. A migration is done when regression is impossible to merge, not when the old code is gone.

Useful ratchets:

- unit tests for new boundary behavior
- tests proving forbidden fields are stripped or rejected
- inventory tests that AST-parse production files for old symbols, including constructed strings, with meta-tests of the detector itself
- denylist tests over caller-visible schemas so authority-shaped parameter names cannot reappear
- structural surface tests that pin properties, not instances (a read-only fake asserts no write route exists)
- schema-anchor tests against real vendor artifacts checked into the repo, including negative anchors on legacy paths
- eval metadata checks for expected tool, expected authorization, persona, and fixture grounding
- integration tests that exercise the real data path instead of mocked trust facts
- tests that prove async acknowledgements do not remount, duplicate, or lose user-visible state
- tests for when polling starts, continues, and stops
- focused adapter tests for provider-specific wire shape
- schema tests for absent, empty, null, and invalid boundary values
- repository tests that prove scoping predicates are part of writes and deletes
- service tests proving side effects happen only after successful persistence

When an inventory allowlist exists, shrink it as migration work completes.

For workflow fixes, prefer a boundary coverage ladder: the thinnest useful test at each crossed boundary instead of one giant top-level test. A typical ladder is schema or DTO, repository scope, service side effect, action or controller response, UI behavior, and one end-to-end happy path when the real path matters.

For inventory-test recipes, fake taxonomy (fixture vs emulator), suppression-baseline burn-down, and LLM boundary hardening, read [references/ratchets.md](references/ratchets.md).

### 11. Ground Evals in Fixtures

When the codebase has an eval suite (LLM or otherwise), treat it as the executable product contract: expectations grounded in seeded fixture content, run provenance recorded, deterministic evaluators fencing any LLM judge, one grounded row per product surface, and mechanism pinned tightly while phrasing is pinned only to the invariant word.

For the full method, use the `grounded-evals` skill.

### 12. Leave Invariant Notes

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

For big changes, docs are first-class commits: design doc with an ownership table, decision records with rejected alternatives, cutover checklist, closeout note, and open product questions escalated by name. See [references/big-change-playbook.md](references/big-change-playbook.md).

## Workflow

1. State the invariant.
2. Inventory current violations with `rg`.
3. For big changes, plan the campaign: collapse → stabilize → ratchet, and the feature-last commit sequence.
4. Choose the smallest boundary slice that can be migrated end to end.
5. Add or update tests that define the desired boundary behavior.
6. Introduce exact typed inputs and outputs; cut seams at the incumbent's shape.
7. Move decision logic to the owning module or registry.
8. Prove the path with a tests-only slice before moving behavior.
9. Split stable and volatile data paths when refresh, polling, pagination, or caching is involved.
10. Preserve absent, empty, null, and invalid as distinct states at update boundaries.
11. Update callers to use the new boundary.
12. Remove bypasses for that slice; drain suppression baselines.
13. Shrink inventory allowlists or add a new guard.
14. Run focused checks, then the quiet broad checks available in the repo.

## Skill Output

When reporting back, include:

- invariant changed or protected
- old surface removed or narrowed
- new boundary shape
- tests/guards added
- docs artifacts written (design, decisions, open questions), if any
- remaining migration surface, if any
- unresolved questions at the end, if any

Do not describe the work as copying a person. Describe the architectural principle and the local codebase effect.

## Review Checklist

- [ ] Did orchestration get simpler?
- [ ] Did any pass-through layer remain without earning its interface?
- [ ] Are trusted facts derived by the owner, not accepted from callers?
- [ ] Do credentials and caller-visible schemas carry identity and business parameters only, never authority?
- [ ] Did broad context shrink into exact boundary data?
- [ ] Do cross-cutting choices route through one registry instead of caller branching?
- [ ] Are old fallbacks removed or tracked, and suppression baselines drained?
- [ ] Are stable and volatile data paths split where refresh or caching would otherwise overfetch?
- [ ] Are provider-specific wire shapes isolated behind typed adapters?
- [ ] Do update boundaries preserve absent, empty, null, and invalid distinctly?
- [ ] Are forbidden fields guarded by tests?
- [ ] Do detected user mistakes warn, block, and offer consequence-named choices instead of auto-correcting?
- [ ] Did tests cover the boundary ladder instead of only implementation details?
- [ ] Are deletions pinned by structural inventory ratchets?
- [ ] Are eval expectations fixture-grounded with provenance, and LLM judges fenced by deterministic evaluators?
- [ ] For big changes, did commits land boundary-first and feature-last, with the path proven before behavior moved?
- [ ] Did the final explanation avoid naming this skill or any person in project artifacts?
