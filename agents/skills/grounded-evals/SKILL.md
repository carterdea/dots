---
name: grounded-evals
description: Design, ground, and harden eval suites for LLM/agent systems. Use when the user wants to add evals or regression datasets, fix flaky or vacuous evals, pin agent behavior like tool routing or authorization, add answer-quality guards or deny lists, ground eval expectations in fixtures, set up LLM-as-judge scoring, or decide when an eval batch can become a CI gate.
---

# Grounded Evals

An eval suite is the executable product contract. It fails in two directions: **flaky** (over-constrained phrasing, ungrounded expectations, judge noise) and **vacuous** (passing without testing anything). Every rule below closes one of those two holes.

Core stance: **determinism scores behavior; judges score quality.** Deterministic evaluators pin what the system *did* (tools called, counts, scope, authorization). An LLM judge scores only how well it *said* it — and only on rows that explicitly opt in. Judge noise must never be able to mask a behavior regression.

## Suite Architecture

- **Evaluators are pure functions in a registry.** Each takes `(outputs, example)` and returns a typed score with a comment. The suite is a tuple of evaluators applied to every row, so a new invariant costs one function plus one registry line and covers every current and future row.
- **Rows opt in; evaluators never punish silence.** A row that declares no expectation for an evaluator scores 1.0 with comment "n/a". This convention is what makes suite-wide composition safe.
- **Pair presence with content.** A separate presence evaluator fails empty output, so content checks can never pass vacuously on empty text.
- **Harden extraction before asserting.** A content assertion is only as trustworthy as the extraction feeding it. Make output-text extraction a total function over every shape the pipeline emits (strings, mappings, lists, nested payloads), walk keys in trust order — the most-final designated field first, rawest last — and pin the extraction itself with a nested-shape unit test.
- **Failure comments name the culprit** (`present=['the tool has found']`) so failures are self-diagnosing without a rerun; assert on comments in the evaluator's own tests.
- **Cache judge calls** on (query, expected, response) so reruns are cheap and stable.

## Grounding

- **Expectations come from fixtures, not invention.** Required substrings are concrete facts from the seeded corpus ("6 weeks", "6 months of service"), so the row fails when retrieval degrades, not when phrasing drifts.
- **Verify grounding mechanically.** Parse the fixture sources into a catalog and assert every dataset row's grounding records resolve against it. Datasets cannot silently reference facts the fixtures don't contain.
- **Fixtures are deterministic named profiles**, not random-ish builders. Pin the fixture contract with exact-value tests *before* anything consumes it. If a fake imitates a real vendor, hold it to schema-anchor tests against real vendor artifacts checked into the repo; if it's just your test data behind an API shape, contract-pin tests suffice.
- **Record provenance per run:** git commit/branch/dirty flag, dataset hash, fixture seed, repetition count. Results without provenance are folklore.

## Dataset Design

- **One grounded row per product surface**, not N near-duplicates: happy path, authorization denial, product gap ("data doesn't exist"), dry-run/approval preview, and persona flips (same query, different role, opposite expected behavior — pin both).
- **Denials and gaps are designed surfaces.** A denial row still pins that the system *consulted* the right tool and that the answer explains access — failure paths get contracts too.
- **Row IDs read as sentences with a greppable family suffix** (`tool_use_role_update_dry_run_preview_answer_quality`), so a guard family can be found with one search.
- **Every quality row also pins the mechanism** (required tool, forbidden tools, call-count and source-count ranges), so it doubles as a routing regression test.
- **Tighten mechanism, loosen phrasing.** Pin behavior exactly; pin wording only down to the invariant word (a good denial must contain "access", not the subject's name). Strict mechanism avoids vacuous evals; minimal wording avoids flaky ones.
- **Keep row-local expectations as documentation.** When a row exists because of an observed failure, its local deny list records the exact observed phrases even if a global list also covers them — the row survives edits to the global list, and the global list protects rows nobody annotated.

## Guard Deny Lists

For "the answer must never contain X" guards (internal tool names, planning monologue, chain-of-thought vocabulary):

- **Two tiers:** plain lowercase substrings for unambiguous internal vocabulary (recall), and anchored regexes only where a bare word would false-positive — e.g. tool names matched only with call syntax `name(` (precision).
- **Ship a should-NOT-fire test** for legitimate vocabulary that resembles denied terms (a product name that shares a prefix with a tool namespace). Guards get precision tests, not just recall tests.
- Keyword guards belong at the *test* boundary where determinism is the point; in *production* behavior, classification stays with the model.

## Operations

- **Lint datasets like code:** JSONL syntax validation, duplicate-ID checks, compile checks on evaluator modules.
- **Dataset is the authority.** When tool names change, map old-to-new in an alias table inside the evaluators instead of editing rows.
- **Narrow dev slice first.** Run a small gate slice during development; expand to full batches before merge.
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
