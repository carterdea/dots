# Big Change Playbook

How to stage a large architectural change so every step is reviewable, behavior-preserving until the cutover, and impossible to regress afterward.

## Campaign shape (PR series)

Big improvements land as a series, not one PR:

1. **Collapse** — the large simplification PR. Delete layers, collapse orchestration, remove the old architecture. Net-negative runtime code is the success signal: report runtime files, runtime lines, and duplicate transports or adapters before and after. Total diff may grow because tests grow.
2. **Stabilize** — fix routing and behavior on the simplified surface, judged by the measurement harness.
3. **Ratchet** — small surgical PRs that pin the simplified system's behavior with deterministic guards. These are cheap only because the collapse made the surface small.

Architectural simplification is what makes cheap deterministic guards viable. Don't ratchet a surface you're about to collapse.

## Plan as a dependency graph

- Start from an audit whose findings carry ids; every task names the finding it serves.
- Each task names files, occurrence counts, and the target shape at each site. Split large migrations by subsystem.
- Test tasks block the wiring they guard, so nothing ships ahead of its proof.
- Verify the plan against current code and vendor docs before building. Record verified vendor behavior with source links.
- Bugs found along the way become new tasks; the PR ships its scope.
- After implementation, a fresh-context pass reads each task's spec, finds the code, and files anything skipped, partial, or wrong as a new task.

## Commit sequence within a big PR (feature last)

Stage commits so each stands on verified ground:

1. **Boundary** — the type/seam migration, behavior preserving.
2. **Ground truth** — deterministic fixtures and fake data the system will be judged against.
3. **Harness** — the measurement layer: evals, provenance, dataset normalization.
4. **Behavior** — stabilization changes, judged by commits 2–3.
5. **Tooling** — ratchets: inventory tests, suppression-baseline burn-down, pre-push hooks.
6. **Feature** — the headline user-facing change, last and smallest, on top of everything above.

The PR may be *named* after commit 6, but commits 1–5 are the real work. Expect a majority of the diff to be verification machinery; test lines exceeding prod lines is normal for this kind of PR.

## Seam mechanics

When migrating a boundary (new provider, new vendor, new backend):

- **Cut the seam at the incumbent's shape.** The new interface's result type can literally alias the old one (`HRResult = IncumbentResult`); the new adapter maps into the field names existing consumers already eat. Migrate consumer vocabulary in a later slice.
- **The incumbent adapter is a pure delegation shim** — a frozen structure whose fields are the pre-existing functions, each method a one-line forward. Zero behavior moves in the seam-creation commit; behavior moves only once the seam exists.
- **Design fully, implement minimally.** The richer target contract lives in the design doc, not the code. Write the debt, the de-drift plan, and anti-drift rules ("consumers may not depend on incumbent-specific field names") into the same commit that incurs the debt.
- **One registry owns the choice.** Provider/vendor/tenant selection lives in exactly one registry keyed by trusted context — never `if provider == ...` branching in tools, auth helpers, or adapters. Future routing changes (env-level today, per-tenant tomorrow) plug into the same insertion point.
- **Unsupported capability fails closed** with an explicit typed error, never partial or fake data.

## Prove the path

After wiring the seam, land a **tests-only commit** that demonstrates existing callers route through the new implementation end-to-end (mock transport at the outermost edge, assertions at the innermost). Separating *building* the seam from *proving* it makes the riskiest claim of the PR independently reviewable.

Then migrate in micro-slices — scaffold fake service, add fixtures, pin fixture contract, add client config, implement mapping, wire registry — with each fix commit pairing prod and test changes at roughly 1:1.

## Atomic cutover vs phased

Record the decision with its inputs. Atomic cutover (no BC facade, no legacy name routing, no deprecation window) is right when only one caller exists and you control it. Phased is right when callers are external. Either way, write a short decision table including the rejected alternative and why.

Atomic in code is not atomic in deploy. When a contract crosses services that restart independently, make it survive a half-upgraded deploy: new fields optional, the client sends a contract revision (header or field), and the server answers older revisions with the older shape. Either side can restart first.

## Data migrations

- Stage schema changes: backfill, then index, then constraint. Add foreign keys `NOT VALID` and validate separately; set lock timeouts.
- Conflicting data fails the migration with review instructions; never pick a winner silently.
- Amend or squash migrations that have not merged instead of stacking fix-up migrations.
- Data-fix scripts live in the repo with a dry-run mode, so they can be reviewed and rerun.
- Read-time compatibility for old persisted shapes is a fallback like any other: pair it with a backfill or a tracked deletion.

## Docs are first-class commits

A big change ships these artifacts in the repo, in the same PR:

- **Design doc** with a two-column ownership table (what the tool/consumer layer owns vs what the adapter/provider layer owns), the target contract, and the shipped-vs-target gap.
- **Decision records** with rejected alternatives and the trigger that would revisit them ("provider choice is deploy-level configuration unless the deployment model changes").
- **Cutover checklist** written before hardening starts.
- **Ownership map** (`ARCHITECTURE.md` or the repo's equivalent) updated in the same commit that moves ownership, one short bullet per fact.
- **Closeout note** when a workstream ends, so the next person knows what was finished vs abandoned.
- **Open product questions escalated by name** — list the concrete decisions a human owner must make; don't silently pick.

A design plan may be deleted before merge as scaffolding only after its decisions, rejected alternatives, and ownership have landed in a durable doc.

## Product contract as a versioned artifact

When behavior is specified by an external artifact (customer spreadsheet, spec doc):

- Cache it in-repo with hash, export date, and provenance — treat it like a supply-chain artifact.
- Mirror it into executable form (eval datasets, unit tests named after contract rows) so cheap CI approximates the expensive judged suite.
- Write down the authority ordering explicitly, e.g.: evals > spec artifact > current code > vendor API shapes. When sources disagree, the higher authority wins and the lower one gets fixed.

## Verification-as-protocol PR body

The PR description is a replayable protocol, not prose:

- Exact commands per tier: focused test naming the highest-risk boundary, dataset lints (JSONL syntax check, duplicate-ID check), compile/lint/typecheck, full suite.
- Grounded eval rerun results with per-evaluator scores and the archived result file path.
- For each new test or eval: that it fails without the fix (quote the failure) and passes with it.
- Replay evidence for external writes: same input run twice against a sandbox, with the provider write count.
- Dry runs against real data shapes with side effects off (no texts or emails sent, read-only DB client).
- **Not verified**: what fixture proof covers vs what still needs a live check, named as the one check still owed.
- **Not changed, on purpose**: deliberate omissions with the reason.
- **Known failures**: checks that are red and why, never hidden.
- **Operational handoff** when the change needs one: restart order, data the PR does not fix, installed config still to update.
- Root cause of any infra red herring hit along the way, so nobody re-debugs it.

Skip raw test-count dumps and evidence from superseded heads; they go stale and bury the protocol. Answer review findings with "Fixed in <sha>: what changed + what proves it", or decline with the reason. A fresh-context AI review is a useful extra pass, not a substitute for a human reviewer.
