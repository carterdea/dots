# Backpressure And Portless Reference

Use this when wiring quiet checks, agent instructions, and stable local URLs.

## `run_silent.sh`

Copy `scripts/run_silent.sh` into the target repo at `scripts/run_silent.sh` and `chmod +x` it. Skip if the file already exists.

The rule is:

```bash
run_silent "typecheck" "bunx tsc --noEmit"
# success: one compact success line
# failure: failure line plus full command output
```

Use it in CI scripts, composite package scripts, `verify:silent` targets, and agent-driven workflows where verbose green output wastes context. Wrap each distinct check in its own call so failures isolate cleanly.

Source: https://www.humanlayer.dev/blog/context-efficient-backpressure

## Agent Instructions

`CLAUDE.md` is canonical. `AGENTS.md` is only a relative symlink to it.

- If `AGENTS.md` exists as a regular file, stop only the agent-instructions reconcile path and log the manual merge instruction from `SKILL.md`.
- Otherwise create `CLAUDE.md` if missing and create `AGENTS.md -> CLAUDE.md` if missing.
- Append Cursor `.cursor/rules/*.mdc` snippets separately only when rules already exist.

Append the stack-specific run-silent snippet:

- TS / JS: `resources/agent-instructions.run-silent.ts.snippet.md`
- Python: `resources/agent-instructions.run-silent.py.snippet.md`
- Ruby: `resources/agent-instructions.run-silent.rb.snippet.md`

Each snippet has a sentinel. Skip only if that exact stack sentinel is present.

Append the stack-specific Portless snippet:

- TS / JS: `resources/agent-instructions.portless.ts.snippet.md`
- Python: `resources/agent-instructions.portless.py.snippet.md`
- Ruby: `resources/agent-instructions.portless.rb.snippet.md`

Per-stack sentinels allow mixed monorepos to carry multiple snippets.

## `.gitignore`

Append only, never rewrite:

```gitignore
test-results/
/qa/screenshots/
/qa/reports/
```

Ignore concrete QA artifact directories rather than all of `qa/`, because repos may source-control QA automation under that tree.

## Portless

Portless gives stable `https://<project>.localhost` URLs and worktree-prefixed URLs. Install globally, never per repo.

```bash
bun add -g portless
```

If Bun is unavailable, fall back to `npm install -g portless`.

Trust the local CA only when interactive:

```bash
if [ -t 0 ] && [ -z "${CI:-}" ]; then
  portless trust
else
  echo "skipped: run 'portless trust' manually after baseline finishes"
fi
```

Do not rewrite source files for Portless. For TS/JS, keep the existing `dev` script. For Python/Ruby, put the invocation in the agent instruction snippet.

Docker aliases are explicit and project-specific:

```bash
docker run -d -p 5432:5432 postgres:16
portless alias db 5432
portless alias --remove db
```

Do not auto-generate Docker alias scripts.

Portless is pre-1.0; if trust warnings reappear after upgrade, tell the user to re-run `portless trust`.

## Files Produced

- `biome.json`
- `[tool.ruff]` and `[tool.basedpyright]` blocks in `pyproject.toml`
- `.rubocop.yml` and `.rubocop_todo.yml`
- `fallow.json` only if fallow cannot infer from the framework
- `lefthook.yml`
- `.github/workflows/ci.yml`
- `scripts/run_silent.sh`
- `CLAUDE.md` canonical file and relative `AGENTS.md` symlink
- global `portless`
