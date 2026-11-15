# Backpressure And Portless Reference

Use this when wiring quiet checks, agent instructions, and stable local URLs.

## `run_silent.sh`

Copy this skill's `scripts/run_silent.sh` into the target repo at `scripts/run_silent.sh` and `chmod +x` it. Skip if the file already exists.

`run_silent` takes a description plus the command as separate arguments — an argument vector, never one quoted string:

```bash
run_silent "typecheck" bunx tsc --noEmit
# ✓ typecheck                      success: one compact line, output discarded
# ✗ typecheck + command + output   failure: command echoed (secrets redacted)
# ⊘ typecheck (skipped: <reason>)  command printed "skipped: …" and exited 0
```

Set `VERBOSE=1` to stream raw output live.

Use it in CI scripts, composite package scripts, `verify:silent` targets, and agent-driven workflows where verbose green output wastes context. Wrap each distinct check in its own call so failures isolate cleanly.

Source: https://www.humanlayer.dev/blog/context-efficient-backpressure

## Agent Instructions

`AGENTS.md` is the only agent file. Claude Code, Codex, Cursor, OpenCode, and pi all read it. Never create `CLAUDE.md` or a `CLAUDE.md -> AGENTS.md` symlink.

AGENTS.md says why the project exists, what good looks like, and how the pieces fit at a high level, then links to the detailed docs. It is not a style guide: Biome, Ruff, Rubocop, and the type checker already enforce the mechanical rules, so do not restate them.

Reconcile:

- `AGENTS.md` exists: leave it alone. If it names no lint, typecheck, test, or dev command, append the `## Working here` section from the template and report it.
- Only `CLAUDE.md` exists, as a real file: log `CLAUDE.md found — git mv CLAUDE.md AGENTS.md, then re-run baseline.` and skip the rest of this path.
- Neither exists: write `AGENTS.md` from `resources/agents-md.template.md`.

Writing a new AGENTS.md:

- Draft each section from `README.md`, the manifest's description, and the code layout. State only what the repo supports. When the repo cannot answer a section (usually Why it exists, Scope, or Principles), drop it and list it as an open question in the report; never invent a goal, user, or status.
- Fill Working here with the commands that exist: the package scripts or tool commands the hooks call, and the dev command. Prefer the repo's quiet variant when a script wraps `run_silent.sh`. Keep it a table, no prose about how the tools work.
- Dev command: TS/JS uses bare `portless`, which runs the `package.json` `dev` script (in a workspace root it starts every package with a `dev` script; name the per-app form instead). Python and Ruby pass the command and `$PORT` explicitly, for example `portless run uv run uvicorn app.main:app --port $PORT --host 127.0.0.1` or `portless run bundle exec rails server -p $PORT -b 127.0.0.1`.
- Docs links only to files that exist. Do not create architecture or stack docs to link to.
- Remove the template's HTML comments. Aim for under 100 lines.

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

Do not rewrite source files for Portless. For TS/JS, keep the existing `dev` script. For Python/Ruby, put the invocation in AGENTS.md's Working here table.

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
- `AGENTS.md` (new repos only)
- global `portless`
