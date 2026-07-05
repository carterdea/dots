<!-- baseline:run-silent:ts -->
## Context-efficient commands

Wrap long-running checks with `scripts/run_silent.sh` so terminal output stays lean for agents. Source: https://www.humanlayer.dev/blog/context-efficient-backpressure

```bash
source scripts/run_silent.sh
run_silent "typecheck" bunx tsc --noEmit
run_silent "lint"      bunx biome check .
run_silent "dead code" bunx fallow --quiet --fail-on-issues
run_silent "tests"     bun run test
```

fallow needs both flags here: without `--fail-on-issues`, warn-level findings exit 0 and render as a false ✓; `--quiet` drops its stderr progress noise from the failure dump.

- Pass the command as separate arguments, not one quoted string.
- Success prints `✓ <description>` only; failure prints `✗ <description>`, the command, and full captured output.
- A check that prints `skipped: <reason>` and exits 0 renders as `⊘` so a skipped check never reads as a pass.
- Set `VERBOSE=1` to stream raw output live.

Use when running multiple checks in sequence, in CI scripts, or any agent-driven workflow where command output lands in a context window. Wrap each distinct check in its own `run_silent` call so failures isolate cleanly.
