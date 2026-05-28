<!-- baseline:run-silent:rb -->
## Context-efficient commands

Wrap long-running checks with `scripts/run_silent.sh` so terminal output stays lean for agents. Source: https://www.humanlayer.dev/blog/context-efficient-backpressure

```bash
source scripts/run_silent.sh
run_silent "lint"  "bundle exec rubocop"
run_silent "tests" "bundle exec rspec"
```

- Success prints `✓ <description>` only.
- Failure prints `✗ <description>` followed by full captured output.

Use when running multiple checks in sequence, in CI scripts, or any agent-driven workflow where command output lands in a context window. Wrap each distinct check in its own `run_silent` call so failures isolate cleanly. (Swap `bundle exec rspec` → `bundle exec rake test` for Minitest projects.)
