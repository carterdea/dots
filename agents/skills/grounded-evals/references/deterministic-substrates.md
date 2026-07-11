# Deterministic Substrates

Making the ground under an eval suite deterministic: fake vendors, retrieval stand-ins, reset protocols, and knowing what conclusions each substrate licenses.

## Stand-ins have behavior, not lookup tables

When replacing a fuzzy component (vector retrieval) with a deterministic stand-in:

- Give it real, simple behavior — keyword tokenization, stop words, a curated synonym-expansion table, scoring with deterministic tie-breaks — not a query→response table. A lookup table breaks the moment a row is rephrased and proves nothing about the response pipeline.
- Return the **exact typed response shapes** of the live component, so the full formatting/citation path is exercised.
- **Weld it to the dataset:** a unit test iterates every eval-dataset query against the stand-in and asserts each retrieves its intended fact. You can't add a row the fixture can't serve, or starve an existing row by editing the fixture, without a cheap test failing first.

## Know the substrate boundary

A deterministic retrieval stand-in licenses conclusions about **tool choice, routing, and answer assembly — never retrieval quality**. A synonym table keyed to dataset vocabulary can't discover that real vector retrieval would miss. Keep at least one suite on the live substrate for retrieval-quality claims.

## Env-gated substrate swap

- The gate is checked **inside the production tool implementation** at one point, off by default, falling through to the live path.
- Each eval suite **declares its env map in the target registry** — substrate choice is a property of the suite, not ambient developer environment.
- Runners apply and restore the env around the run (snapshot prior values, pop keys that didn't exist, try/finally), so one suite's substrate can't leak into the next. Note: process-global env mutation forbids parallel multi-target runs in one process — pin those targets serial.

## Provenance tags per artifact

Every retrieved artifact carries a provenance tag (fixture vs live store vs vendor), stamped by each substrate into its results. The eval run projects the set of provenances observed into eval metadata, so a suite can **prove it exercised the intended substrate** — and detect leakage to the real one (CI accidentally hitting production, or the fixture answering in prod).

## Reset is a declared, tested protocol

A fake vendor is not deterministic unless it is resettable:

- An authenticated **admin reseed endpoint** clears storage and force-reseeds to canonical fixture state; optionally reseed-on-start.
- Each suite **declares whether it needs reset** in its target spec; runners reset before the run, with an env kill-switch and configurable timeout.
- Unit-test the reset **protocol** (URL, headers, timeout, error propagation, against a fake HTTP client) and pin reset **semantics** with a business-fact snapshot test: snapshot facts, reset, re-snapshot, assert equality — reset provably means "back to canonical," not "empty."
- E2E consistency tests get an autouse reset so manual local mutations can't poison assertions.

## Seed identity is derived, never sampled

- Fixed epoch for all dates; business dates derive as offsets from it.
- IDs from namespace hashing (uuid5-style) of resource + offset — never random UUIDs, never wall-clock.
- Deterministic list ordering. Re-seeds, restarts, and parallel environments produce byte-comparable data.

## Layered suite splits

Verify the substrate in layers that mirror the failure modes, each independently runnable so a red eval names its layer:

1. **Emulator alone** — the fake vendor's endpoints.
2. **Tool contract** — the tool layer against stubbed transport.
3. **Tool layer against the live emulator** — integration.

Boot the emulator hermetically per invocation: ephemeral port, temp database, health-poll with a deadline, dump the server log on failure, clean up via trap.

## Tool-trace for layer bisection

Attach a compact trace to every vendor-adapter result — method, path, item count, matched item IDs (extracted via a trust-ordered key list over a total payload walker). When an eval row fails, bisect: wrong tool chosen (agent), right tool but wrong route/records (tool layer), or right records but wrong prose (formatting).
