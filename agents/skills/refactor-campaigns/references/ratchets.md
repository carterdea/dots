# Ratchets

Recipes for making deletions permanent. A migration is done when regression is *impossible to merge*, not when the old code is gone.

## Inventory ratchets (structural tests)

- **AST-scan the production tree.** Parse every production source file and assert the deleted symbol appears nowhere: names, attributes, args, keywords, aliases, function names, and string constants.
- **Detect constructed strings.** Fold concatenations (`"auth" + "orization" + "_context"`) back to literals before matching, so string tricks can't smuggle the symbol back in.
- **Meta-test the detector.** The inventory test's own detection logic gets unit tests proving it catches the evasions it claims to catch.
- **Denylist the boundary surface.** For caller-visible schemas (tool params, DTO classes), assert no declared parameter matches a denylist of authority-shaped names (`role`, `permissions`, `scope`, `authorized_*_ids`, …). This enforces the trust boundary mechanically, forever.
- **Allowlist the tolerated exceptions** in a named constant so drift is visible in the diff, and shrink it as migration completes.
- **Fragment legitimate remnants.** If one legacy string must survive (e.g. a strip-key for the old parameter name), write it deliberately fragmented (`"mcp" + "_auth" + "_token"`) so grep-based inventories don't count it as live usage.
- **Drain suppression baselines to zero.** Type-checker baselines, lint ignores, and skip lists are ratchets too: burn them down in the same PR, then nothing can hide behind them.
- **Pin structural properties, not instances.** A read-only fake gets a test that iterates its routes and asserts no write method exists — the property can't regress by adding one endpoint.

## Fakes: fixture vs emulator

Name which kind of fake you're building; each gets a different correctness regime:

- A **fixture** is *your* test data behind an API shape. Correctness = contract-pin tests asserting exact fixture values verbatim, before anything consumes them, plus structural surface tests (read-only, health payload, middleware presence).
- An **emulator** imitates a real vendor. Correctness = **schema-anchor tests** asserting responses path-by-path against real vendor artifacts checked into the repo (Postman collections, recorded payloads), including **negative anchors** (`assert_absent` on legacy paths) that ratchet drift *out*.

## LLM boundary hardening

- **Caller-visible tool schemas contain only business parameters.** Split tools into a public wrapper (model-visible signature) and a private impl that receives identity out of band from infrastructure — a model can't pass, forge, or be injected into supplying trust facts.
- **Strip trust-shaped parameters at the client boundary** before dispatch, and test that stripping.
- **Tokens carry identity, never authority** (who, tenant, session). Roles, permissions, scopes, and authorized-ID lists are re-derived at point of use from the database, with the token's session claims cross-checked against server-side session state. Denial reasons are closed Literal unions, not strings.
- **Enforce blocked surfaces at two layers** (removed from the catalog at startup *and* rejected at dispatch), with tests asserting the impl was never invoked.
- **Derived slices over raw dumps.** Extract the minimal relevant content deterministically before the model sees it; answer "not available" from an authoritative listing rather than letting the model improvise.
- **Rewrite unsafe machine-proposed calls** to the safe form (e.g. force dry-run on writes) rather than denying and degrading UX — and pin the rewrite with a test.
