---
name: grounded-evals
description: Design, ground, and harden eval suites for LLM/agent systems. Use when the user wants to add evals or regression datasets, fix flaky or vacuous evals, pin agent behavior like tool routing or authorization, add answer-quality guards or deny lists, ground eval expectations in fixtures, set up LLM-as-judge scoring, score live production traffic with online evals, or decide when an eval batch can become a CI gate.
---

# Grounded Evals

An eval suite is the executable product contract. It fails in two directions: **flaky** (over-constrained phrasing, ungrounded expectations, judge noise) and **vacuous** (passing without testing anything). Every rule below closes one of those two holes.

Core stance: **determinism scores behavior; judges score quality.** Deterministic evaluators pin what the system *did* (tools called, counts, scope, authorization). An LLM judge scores only how well it *said* it — and only on rows that explicitly opt in. Judge noise must never be able to mask a behavior regression.

## Suite Architecture

- **Evaluators are pure functions in a registry.** Each takes `(outputs, example)` and returns a typed score with a comment. The suite is a tuple of evaluators applied to every row, so a new invariant costs one function plus one registry line and covers every current and future row.
- **Rows opt in; evaluators never punish silence.** A row that declares no expectation for an evaluator scores 1.0 with comment "n/a". This convention is what makes suite-wide composition safe.
- **Pair presence with content.** A separate presence evaluator fails empty output, so content checks can never pass vacuously on empty text.
- **Project internals into an eval metadata contract.** The target adapter translates the system's trajectory (tool calls, retrieval results, sources) into namespaced `eval_*` keys; evaluators consume only that contract, never system internals. Unit-test the projection with stub workflows so agent refactors break one tested seam, not every evaluator.
- **One judge call, fanned out.** Ask the judge for a single structured verdict per row (score, passes, reasoning, missing critical details, unexpected problems, confidence), cache it on (query, canonicalized expected, response), and register one deterministic evaluator per verdict field. The cache is a consistency invariant — every column grades the same verdict — not just a cost saver.
- **Give the judge an open-world field.** A `unexpected_problems` list — defects the expectation never mentioned — asserted empty. Closed-world fields catch expectation misses; the open-world field catches expectation blind spots.
- **Judging fails closed.** Empty response scores 0 *before* the judge is invoked; unparseable judge output scores 0 with "parse failed"; a dedicated error-channel evaluator separates "the system errored" from "the system answered badly" so infra failures can't masquerade as quality regressions.
- **Pass = judge's own verdict AND score ≥ config threshold.** The judge can fail a row unilaterally but never pass one the numeric bar rejects; rows may override the threshold.
- **Declare concurrency in the target spec.** Targets that mutate ambient state (request context, seeded DB rows) pin serial execution in the registry, so no runner flag can race them.
- **Harden extraction before asserting.** A content assertion is only as trustworthy as the extraction feeding it. Make output-text extraction a total function over every shape the pipeline emits (strings, mappings, lists, nested payloads), walk keys in trust order — the most-final designated field first, rawest last — and pin the extraction itself with a nested-shape unit test.
- **Failure comments name the culprit** (`present=['the tool has found']`) so failures are self-diagnosing without a rerun; assert on comments in the evaluator's own tests.

## Grounding

- **Expectations come from fixtures, not invention.** Required substrings are concrete facts from the seeded corpus ("6 weeks", "6 months of service"), so the row fails when retrieval degrades, not when phrasing drifts. Tight phrasing is safe exactly when the phrase is a fixture-authored fact.
- **Verify grounding mechanically.** Parse the fixture sources into a catalog and assert every dataset row's grounding records resolve against it. Datasets cannot silently reference facts the fixtures don't contain.
- **Weld fixture to dataset with a coverage test.** A unit test iterates every dataset query against the deterministic fixture and asserts each retrieves its intended fact — neither can drift without a cheap test failing before the expensive eval runs.
- **Fixtures are deterministic named profiles**, not random-ish builders: fixed epoch for all dates, namespace-hashed IDs, deterministic ordering. Pin the fixture contract with exact-value tests *before* anything consumes it, and make the fixture *resettable* — reseed before every run, with a reset-equivalence snapshot test proving reset means "back to canonical," not "empty."
- **Name aspirational rows.** Spec- or stakeholder-derived expectations not grounded in fixtures are a distinct row class: judge-mode only, semantic-target framing, never substring-pinned — and a promotion blocker until grounded.
- **Record provenance per run:** git commit/branch/dirty flag, dataset hash, fixture seed, repetition count. Results without provenance are folklore.

For deterministic stand-ins for fuzzy components (vector retrieval, vendor APIs), reset protocols, substrate provenance tags, and env-gated substrate swaps, see [references/deterministic-substrates.md](references/deterministic-substrates.md).

## Dataset Design

- **One grounded row per product surface**, not N near-duplicates: happy path, authorization denial, product gap ("data doesn't exist"), dry-run/approval preview, and persona flips (same query, different role, opposite expected behavior — pin both).
- **Denials and gaps are designed surfaces.** A denial row still pins that the system *consulted* the right tool and that the answer explains access — failure paths get contracts too.
- **Should-not-act rows pin absence on every axis** — zero tool calls, zero sources, the mutating tool explicitly forbidden — *and* still require the refusal to name the request's subject, so a generic canned deflection can't pass.
- **Row IDs read as sentences with a greppable family suffix** (`tool_use_role_update_dry_run_preview_answer_quality`); imported rows carry their origin corpus in the ID prefix and keep the source's lineage columns (origin, category, author notes) in the row. Firewall lineage from the judge: bookkeeping fields are context-only, never gradeable content.
- **Every quality row also pins the mechanism** (required tool, forbidden tools, call-count and source-count ranges), so it doubles as a routing regression test. When forbidden lists become mechanical complements of required tools across a suite, allow a suite-level exclusive-tool default with row overrides.
- **Tighten mechanism, loosen phrasing — and encode it in the judge prompt.** Pin behavior exactly; pin wording only down to the invariant word. Tell the judge explicitly that the expectation is a semantic target, not a literal template, and enumerate its grading axes.
- **The dev slice is a registered sibling suite** with its own committed dataset file, same target and evaluators — reproducible and comparable across runs, not an ephemeral `--limit` flag.
- **Keep row-local expectations as documentation.** When a row exists because of an observed failure, its local deny list records the exact observed phrases even if a global list also covers them — the row survives edits to the global list, and the global list protects rows nobody annotated.

## Guard Deny Lists

For "the answer must never contain X" guards (internal tool names, planning monologue, chain-of-thought vocabulary):

- **Two tiers:** plain lowercase substrings for unambiguous internal vocabulary (recall), and anchored regexes only where a bare word would false-positive — e.g. tool names matched only with call syntax `name(` (precision).
- **Ship a should-NOT-fire test** for legitimate vocabulary that resembles denied terms (a product name that shares a prefix with a tool namespace). Guards get precision tests, not just recall tests.
- Keyword guards belong at the *test* boundary where determinism is the point; in *production* behavior, classification stays with the model.

## Online Evals

Offline suites compare against expectations; online evals score live production traffic where **no gold answer exists**. The core stances:

- A **reference-free judge** grades usefulness-given-request on named dimensions (relevance, completeness, domain fit, groundedness, action safety), fed system telemetry (route, role, tools used, source counts, error state) — it grades a system event, not a string pair.
- **The user never waits for the judge:** fire-and-forget post-response work, sampled by a content-seeded hash bucket (reproducible, stateless), shipped dark (enabled=false, rate=0.0 by default).
- **Capture trace identity by value while the request is alive; attach feedback by ID from deferred work.** Never let deferred work reach for ambient trace context of a request that has ended.
- **Eval hooks are pure additions** to a request path — never bundled with auth, output-shape, or side-effect changes.

For the full method — judge prompt design, feedback writing, streaming capture, non-throwing plumbing, and re-land lessons — see [references/online-evals.md](references/online-evals.md).

## Operations

- **Lint datasets like code:** JSONL syntax validation, duplicate-ID checks, compile checks on evaluator modules.
- **Dataset is the authority.** When tool names change, map old-to-new in an alias table inside the evaluators instead of editing rows.
- **The local runner is a real check, not a report generator:** nonzero exit on any failing evaluator, plus a compact stderr digest of (row, evaluator, comment) so CI logs name the culprit without opening the results file.
- **Match the platform's injection contract exactly.** Evaluator parameter names select what the hosted platform injects — a wrong name silently binds a different object. Write accessors that tolerate both platform objects and plain dicts so the identical evaluator runs locally and hosted.
- **The harness runs where the system runs.** Plumb platform credentials into that environment with empty-safe defaults, and document each target's runtime requirements (DB, secrets, network) in the suite README.
- **Eval accommodations stay at the test boundary.** The target adapter injects tenant/identity explicitly; never add ambient env fallbacks to production code paths to make evals run.
- **Retired suites raise with a reason** — keep the registry name resolvable and make invocation error with why, never silently vanish.
- **Written promotion criteria.** An eval batch becomes a CI gate only when every row has normalized metadata, fixture grounding verifies, summary scores are 1.0, and a timestamped result artifact is archived. Archive failed attempts with their failure reasons; don't delete them.
- **Verification-as-protocol PR body:** the exact replayable commands (focused tests, dataset lints, full grounded rerun), per-evaluator scores, the archived result file path, and the root cause of any infra red herring hit along the way.

## Workflow

1. Name the failure class or product surface being pinned, and whether it's behavior (deterministic) or quality (judge).
2. Read the existing suite: registry shape, extraction helpers, dataset format, fixture sources.
3. Harden extraction if the new assertion depends on it, with its own test.
4. Write the evaluator as a pure registry entry with the "n/a passes" convention; unit-test score and comment, including a precision (should-not-fire) case for any deny list.
5. Add one grounded row per affected product surface, each pinning mechanism tightly and phrasing minimally; verify grounding resolves against the fixture catalog.
6. Lint the dataset (syntax, duplicate IDs) and run the focused suite.
7. Rerun the grounded eval batch; record provenance and archive the result artifact.
8. Report per-evaluator scores and any rows intentionally left ungrounded, with reasons.

Done means: the new invariant fails on the observed bad output, passes on current good output, cannot pass vacuously, and every new row's grounding resolves.
