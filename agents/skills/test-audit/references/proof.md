# Proportional validation

Adapted from OpenClaw's proof policy; see [provenance](../PROVENANCE.md).

## Proof policy

- Follow target repository and scoped instructions, existing runner wrappers, package manager, CI routing, and host limits.
- Read the command, configuration, setup, and test dependencies before running. Never execute unreviewed contributor code or hydrate an untrusted environment with credentials.
- Start with the owning test and meaningful siblings. Use broad CI proof when authorized; do not run a full local suite merely to seek green.
- Prove the changed contract and finish required gates. Broaden or repeat only for changed inputs, failures, or a named unresolved risk.
- Preserve active test runs. Never edit their checkout's source, configuration, or dependencies while a run is active. Follow the target repository's runner; serialize checks unless their state and caches are demonstrably independent.
- Use isolated synthetic state and free ports. Never restart operator services or touch real data without explicit task authority. Preserve unrelated processes and dependency installs.
- Paid/live provider operations need explicit authority. Fixed external I/O fixtures can prove the local boundary; state the live-contract gap.
- Documentation-only changes need link/frontmatter sanity and `git diff --check`, not application builds.
- Record exact command, checkout revision, pass/fail/skip state, timing, and limitations. A missing dependency, setup failure, or unavailable service is not a passing test.

## Test failure policy

- Treat failures as defects to investigate. Bound reproduction, preserving original order where relevant; identify product, fixture, infrastructure, or shared-state ownership.
- Never hide failures with retries, longer timeouts, weaker assertions, broader mocks, or altered baselines.
- An audit does not silently expand into product repair. Report defects and focused repair steps when implementation is outside task scope.
- A proven repair needs a failing pre-fix control and passing candidate on the same harness; report unavailable baseline proof.
- Commit, push, open a PR, merge, deploy, or publish only under the task's authority and repository workflow.
