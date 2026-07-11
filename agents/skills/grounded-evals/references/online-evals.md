# Online Evals

Scoring live production traffic with no gold answer, without ever degrading the user-facing request.

## The judge

- **Name the no-gold condition in the prompt.** Open with the epistemic situation: "There is no gold answer. Judge the response only on whether it is useful, appropriate, and safe for the user's request." A reference-free judge grades a different question than an offline one, and must be told so.
- **Decompose into named dimensions** where at least some are domain- or safety-specific (relevance, completeness, domain fit, groundedness, action safety), not generic fluency.
- **Feed system telemetry, not a bare string pair:** workflow type, route, user role, tools/agents used, source counts, error state. A live judge grades a system event.
- **Bias strictness toward asymmetric failures** — hallucinated facts, unjustified certainty, unsafe approval or access behavior. Online scoring's job is detection, not grading on a curve.

## Architecture

- **Fire-and-forget post-response work.** Enqueue the eval on the framework's post-response task queue; the user path must be unable to block on, slow for, or fail because of the judge. Sampling decides at enqueue time so unsampled requests pay zero cost.
- **Capture by value, attach by ID.** The production trace context is request-scoped and ephemeral; the eval is deferred. Resolve trace identity to plain IDs (run id, trace id) while the context is alive, carry them inside a self-contained typed payload, and attach feedback by explicit ID later. Everything the eval needs — query, response, role, route, telemetry — travels by value in that payload.
- **Streaming: the traced unit is the generator.** A streaming handler returns immediately; the work happens later inside the generator in a different execution context. Put the trace decorator on the generator and capture trace identity right where the final payload materializes, not at request entry.
- **The background task is a fresh execution context.** Re-establish whatever ambient state downstream code assumes (tenant, conversation), and restore by token in a finally — restore prior values, never clear to nothing, or you nuke any enclosing context.
- **Segregate judge telemetry** into its own trace project/namespace, and trace the judge itself, so eval volume never pollutes production dashboards while staying linked via feedback IDs.

## Sampling

- **Content-seeded hash bucket, not `random()`.** Hash the interaction's identity (conversation + query + response + route) to [0,1] and sample below the configured rate. Reproducible (replaying an incident re-derives the decision), uniform without shared state, tunable by config alone. Clamp the rate; short-circuit at 0 and 1.

## Writing feedback

- **One feedback key per dimension plus an aggregate** whose value payload preserves the full structured verdict — the platform can chart and alert per dimension without parsing blobs. Encode "issues present" as an inverted score so it aggregates like any metric.
- **Scores are model outputs and carry provenance:** typed as machine feedback (never conflated with human thumbs), linked to the judge's own trace run for audit, stamped with judge model ID and the threshold in force — scores are only comparable within a (judge, threshold) regime.
- **Pass = judge's own verdict AND score ≥ config threshold**, so the judge can fail unilaterally but never pass what the bar rejects, and operators tighten the bar without re-prompting.

## Non-throwing plumbing

Nothing downstream can catch a deferred exception, so the whole path degrades to logged outcomes:

- Typed coercion on every judge output field; parse failure is a logged, counted outcome, never a crash.
- Missing trace linkage (tracing disabled, context lost) is an expected condition: skip, log with route/conversation, return false.
- Fire-and-forget work fails invisibly by design, so success must be an explicit queryable signal — "eval ran" and "feedback actually attached" are different facts; log both.
- Pin vendor imports to stable module paths, not package re-export surfaces — this code runs on every sampled production request.

## Operations

- **Ship dark.** Enabled flag off and sample rate 0.0 by default in deployment config. Enablement, rate, judge model, and threshold are operational knobs, not code — you'll dial sampling up during an incident and swap judges without a deploy.
- **Tag every event with its surface** (route name) — the primary segmentation axis — and consciously exclude non-user surfaces (debug/internal endpoints) from sampling.
- **Ship a local end-to-end driver** that hits the real endpoint and exercises request → response → background eval; online eval's correctness is only observable by driving the real path.

## Landing it

- **Eval hooks are pure additions.** If the instrumentation diff also changes auth, output shape, or existing side effects, the eval work inherits every one of those risks and dies with them in the revert.
- **Keep the engine self-contained** behind one enqueue function; only a thin router attachment touches request paths. If the attachment has to be reverted, the re-land is a small diff, not a rewrite.
- **Optional at the seam:** the hook parameter defaults to none and the guard returns early, so every pre-existing caller and test works unchanged. Streamed responses need the post-response queue handed off explicitly to the streaming response object.
