# Boundary and cost guide

Adapted from OpenClaw's writing-tests guide; see [provenance](../PROVENANCE.md).

## Prove behavior at the owning boundary

Prove a caller-visible contract through its production owner with fixed external
I/O fixtures and independent expected values. Prefer focused integration tests
and independent unit contracts over mocked internal decisions or whole-product
boots. Name the credible regression and what the test cannot prove.

Work in vertical slices: failing behavior, coherent repair, passing proof.
Regressions must fail on the original defect, not fixture setup; report unavailable
baseline proof. Refactor under green tests and preserve distinct contracts when
consolidating coverage. Use synthetic content and keep credentials out of captures.

For requests, paid calls, recovery, defaults, or performance claims, identify the
observable scenario before changing proof: intended output, persisted effects,
retry/idempotency behavior, failure state, and forbidden side effects.

## Cost budget

Use the target repository's supported focused runner and record wall time for
new or changed tests. Record CI time when available; do not invent measurements.
Honor existing test budgets and routing; never raise a baseline to hide growth.

- Seconds-long tests must prove a contract no cheaper layer can. Expensive whole-product compositions need a distinct reason.
- Prefer under five seconds of test time per file; above thirty seconds, explain the contract and why no cheaper layer proves it.
- Inject clocks rather than sleeping or polling. Isolate files, ports, and state. Reuse a suite-level process fixture when appropriate.
- Await produced state, not just an asynchronous action's return.
- Mock external boundaries and preserve their real API shape. Do not make mocks implement the behavior being asserted.
- Close resources, restore global state, and preserve module identity under the repository's isolation model.
- Reproduce an ordering failure in its original order before running alone. Repair the producer rather than adding retries or timeouts.

Storage and tenant contracts deserve real isolated storage proof where practical.
Mock query assertions can complement that proof but cannot establish transactions,
constraints, lock behavior, or durable persistence.
