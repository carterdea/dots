---
name: baseline
description: Install a quality baseline on a repo — linter, formatter, dead-code scanner, lefthook hooks, and a context-efficient backpressure wrapper.
user-invocable: true
---

# Baseline

First-pass guardrails for vibe-coded repos. Detects the stack and framework, installs the standard toolchain with sane defaults, wires git hooks, drops in a backpressure helper for agent-friendly output.

## When to use

- Fresh repo with no linter / formatter / hooks.
- Vibe-coded codebase that needs a quality floor before more work lands.
- Re-running on a repo to fill in missing pieces — checks what exists, installs only what is missing.

## Non-goals

- Does **not** modernize package managers (npm → bun, pip → uv).
- Does **not** reconcile or merge existing configs. If `biome.json`, `lefthook.yml`, `[tool.ruff]` in `pyproject.toml`, etc. already exist, log "already configured" and skip.
- Does **not** enforce custom rules. Tool defaults + framework presets only.

## Toolchain by stack

| Stack   | Package manager | Tools installed                              |
|---------|-----------------|----------------------------------------------|
| TS / JS | `bun`           | `@biomejs/biome`, `knip`, `lefthook`         |
| Python  | `uv`            | `ruff`, `basedpyright` (or `pyright`), `lefthook` |
| Ruby    | `bundler`       | `rubocop` (+ framework gems), `lefthook`     |

Different manager (npm, pnpm, yarn, pip, poetry): fall back to its idiomatic install command. Do not rewrite lockfiles.

## Steps

### 1. Detect stack

Marker files:

- `package.json` → TS / JS
- `pyproject.toml` or `requirements.txt` → Python
- `Gemfile` → Ruby

### 2. Detect framework (drives config presets)

| Framework         | Marker                                              | Preset applied                                                      |
|-------------------|-----------------------------------------------------|---------------------------------------------------------------------|
| Next.js           | `next.config.{js,ts,mjs}` or `next` in deps         | Biome recommended + `nextjs` + `react` domains; Knip plugin (auto)  |
| React Router v7   | `react-router.config.*` or `@react-router/*`        | Biome recommended + `react` domain; Knip plugin (auto)              |
| Remix             | `remix.config.*` or `@remix-run/*`                  | Biome recommended + `react` domain; Knip plugin (auto)              |
| Vite              | `vite.config.*`                                     | Biome recommended; Knip `vite` + `vitest` plugins (auto)            |
| NestJS            | `@nestjs/*` in deps or `nest-cli.json`              | Biome recommended; Knip `nest` plugin (auto)                        |
| Hono              | `hono` in deps                                      | Biome recommended; Knip auto-detects via entry points               |
| Astro             | `astro.config.*`                                    | Biome `astro` plugin; Knip `astro` plugin (auto)                    |
| Bun runtime       | `bun` in deps or `bunfig.toml`                      | Biome recommended; Knip `bun` plugin (auto)                         |
| Django            | `manage.py` or `django` in deps                     | Ruff preset: `DJ` + `ASYNC` + `B` + `SIM` + `UP` + `I`              |
| FastAPI           | `fastapi` in deps                                   | Ruff preset: `FAST` + `ASYNC` + `B` + `SIM` + `UP` + `I` + `S`      |
| Rails             | `config/application.rb`                             | `rubocop-rails` gem; `require: rubocop-rails` in config             |

Knip auto-detects most framework plugins — no config needed if plugin exists.

Biome has first-class `nextjs`/`react`/`test`/`solid` domains in v2+. For NestJS and Hono, Biome recommended is enough — no dedicated domain exists; Knip handles dead-code detection there.

### 3. Install linter (skip if present)

**TS / JS** — skip if `biome.json` or `biome.jsonc` exists.

```bash
bun add -d --exact @biomejs/biome
bunx biome init
```

Add framework domains to `biome.json` after init:

```json
{
  "$schema": "https://biomejs.dev/schemas/2.0.0/schema.json",
  "linter": {
    "enabled": true,
    "rules": { "recommended": true }
  },
  "assist": { "actions": { "source": { "organizeImports": "on" } } },
  "formatter": { "enabled": true, "indentStyle": "space" }
}
```

For Next.js / React / Remix / React Router: add `"javascript": { "globals": [...] }` as needed and enable React/Next domains per current Biome docs.

**Python** — skip if `[tool.ruff]` present in `pyproject.toml` or `ruff.toml` exists.

```bash
uv add --dev ruff
```

**Ruff selectors, briefly:** Ruff lint rules are grouped by letter prefix (think plugin-per-prefix). Pick prefixes via `select` / `extend-select` in config.

| Prefix   | What it catches                                          |
|----------|----------------------------------------------------------|
| `F`      | pyflakes — unused imports, undefined names (default on)  |
| `E`/`W`  | pycodestyle — style (default on)                         |
| `I`      | isort — import ordering                                  |
| `B`      | flake8-bugbear — likely bugs                             |
| `SIM`    | flake8-simplify — simpler constructs                     |
| `UP`     | pyupgrade — modern syntax                                |
| `S`      | flake8-bandit — security                                 |
| `ASYNC`  | flake8-async — common async footguns                     |
| `FAST`   | flake8-fastapi — FastAPI anti-patterns                   |
| `DJ`     | flake8-django — Django anti-patterns                     |
| `PT`     | flake8-pytest-style — pytest idioms                      |

Baseline config to append to `pyproject.toml`:

```toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
extend-select = ["I", "B", "SIM", "UP", "ASYNC", "PT"]
```

FastAPI detected — extend further:

```toml
[tool.ruff.lint]
extend-select = ["I", "B", "SIM", "UP", "ASYNC", "PT", "FAST", "S"]
ignore = ["S101"]  # allow `assert` in tests
```

Django detected:

```toml
[tool.ruff.lint]
extend-select = ["I", "B", "SIM", "UP", "ASYNC", "PT", "DJ"]
```

**Python typecheck** — install `basedpyright` (preferred, strict-by-default) or `pyright` if user already uses it. Skip if either is in `pyproject.toml` dev deps.

```bash
uv add --dev basedpyright
```

Minimal `pyproject.toml` block:

```toml
[tool.basedpyright]
typeCheckingMode = "standard"
```

**Ruby** — skip if `.rubocop.yml` exists.

```bash
bundle add rubocop --group=development,test
# Rails detected:
bundle add rubocop-rails --group=development,test
bundle exec rubocop --auto-gen-config
```

`--auto-gen-config` writes `.rubocop_todo.yml` so legacy code doesn't block commits. Include via `inherit_from: .rubocop_todo.yml` in `.rubocop.yml`.

### 4. Install knip (TS / JS only)

Skip if `knip.json`, `knip.jsonc`, `.knip.json`, or `knip` key in `package.json` exists.

```bash
bun add -d knip
```

Knip auto-detects common frameworks (Next, Nuxt, Remix, Vite, Vitest, Nest, Astro, SvelteKit, Storybook, Tailwind, ESLint, Playwright, Cypress, Bun). For Hono and other frameworks without a named plugin, Knip still works via entry-point detection from `package.json` `bin` / `main` / `exports`.

### 5. Install lefthook

Skip if `lefthook.yml`, `lefthook.yaml`, or `.lefthook.yml` exists at repo root.

**TS / JS:**
```bash
bun add -d lefthook
bunx lefthook install
```

**Python:**
```bash
uv add --dev lefthook
uv run lefthook install
```

**Ruby:**
```bash
bundle add lefthook --group=development
bundle exec lefthook install
```

Copy the matching template from `resources/` to `lefthook.yml` at repo root. For monorepos, merge templates — see Monorepos section.

### 6. Hook layout

Principle: fast + staged on commit, slow + full-repo on push.

| Tool                 | Pre-commit (staged)       | Pre-push (full)          |
|----------------------|---------------------------|--------------------------|
| Biome                | `--write` staged files    | full repo check          |
| Ruff format + lint   | `format` + `check --fix`  | full repo check          |
| Rubocop              | `-a` staged               | full repo check          |
| Typecheck (tsc)      | —                         | `tsc --noEmit`           |
| Typecheck (basedpyright / pyright) | —           | full project check       |
| Knip                 | —                         | full scan                |
| Vitest               | `--changed` (if fast)     | full suite               |
| `bun test`           | `--changed` (if fast)     | full suite               |
| Pytest               | —                         | full suite               |
| RSpec / Minitest     | —                         | full suite               |

Rule of thumb: if a staged-files mode exists and the command returns in under a few seconds, move to pre-commit. Otherwise pre-push. Typecheckers, knip, and full test suites have no staged mode → always pre-push.

### 7. Drop in the backpressure wrapper

Copy `scripts/run_silent.sh` into the target repo at `scripts/run_silent.sh` (create dir if missing). `chmod +x scripts/run_silent.sh`.

Skip if the file already exists.

### 8. GitHub Actions (quality gate)

Only runs if the remote is GitHub. Check:

```bash
git remote get-url origin 2>/dev/null | grep -q github.com
```

Skip condition: if **any** file exists under `.github/workflows/` → log `GitHub Actions already configured, skipping.` Do not overwrite or merge. User opted in manually or via a different skill.

If no workflows exist → write `.github/workflows/baseline.yml` using the matching template from `resources/github-actions.*.yml`.

**Scope of the workflow: full quality suite for every detected workspace, not just tools this skill installed.** If the repo already has vitest, playwright, pytest, basedpyright, etc., include them. Detect by scanning:

- `package.json` scripts (`test`, `test:e2e`, `typecheck`, `lint`) and deps
- `pyproject.toml` deps (pytest, basedpyright, pyright, mypy, ruff)
- `Gemfile` (rspec, minitest, rubocop)

Build the workflow from detected tools — lint + format-check + typecheck + dead-code + unit tests + e2e tests, per workspace. Mirror pre-push hook commands so local and CI stay in sync.

**Monorepo**: use `resources/github-actions.monorepo.yml` as a base; add one job per workspace with `defaults.run.working-directory` scoped to the package path. Each job runs its own full suite — lint, typecheck, dead-code, tests. Don't share steps across stacks (TS and Py need different setup actions).

**Runners**: `ubuntu-latest`. **Triggers**: `pull_request` + `push` to default branch only (not every push — prevents duplicate runs on PRs).

**Caching**: `astral-sh/setup-uv@v5` and `oven-sh/setup-bun@v2` handle caching via their own flags. Don't hand-roll `actions/cache`.

### 9. Verify

Run each hook once to confirm wiring:

```bash
# TS/JS
bunx lefthook run pre-commit
bunx lefthook run pre-push

# Python
uv run lefthook run pre-commit
uv run lefthook run pre-push

# Ruby
bundle exec lefthook run pre-commit
bundle exec lefthook run pre-push
```

Report: which tools installed, which skipped (already present), which hooks wired.

## Monorepos

Common layouts:

- **pnpm / bun / yarn workspaces** (TS-only): per-package `package.json`, one root lockfile. `apps/web`, `packages/ui`, etc.
- **Mixed TS + Python**: e.g. React frontend + Python `chat-services`. Each sub-project has its own manifest (`package.json`, `pyproject.toml`).
- **Turborepo / Nx**: workspace manifests + task runner.

Rules:

1. **Lefthook at repo root, always.** One `lefthook.yml`. Git hooks live at the top of the work tree.
2. **Linter / formatter per workspace.** Install Biome / Ruff / Rubocop inside each package that has its own manifest. Don't try to lint Python files with Biome or TS files with Ruff.
3. **Glob scoping in lefthook.** Narrow `glob:` to each workspace's file tree, then `run:` the correct CWD:

    ```yaml
    pre-commit:
      commands:
        biome-web:
          glob: "apps/web/**/*.{ts,tsx,js,jsx,json}"
          run: cd apps/web && bunx biome check --write {staged_files}
          stage_fixed: true
        ruff-chat:
          glob: "chat-services/**/*.py"
          run: cd chat-services && uv run ruff check --fix {staged_files}
          stage_fixed: true
    ```

4. **Pre-push: run each workspace's own suite.** One command per workspace for typecheck / knip / tests, so failures isolate:

    ```yaml
    pre-push:
      commands:
        typecheck-web:
          run: cd apps/web && bunx tsc --noEmit
        knip-web:
          run: cd apps/web && bunx knip
        test-web:
          run: cd apps/web && bun run test
        pytest-chat:
          run: cd chat-services && uv run pytest
    ```

5. **Skip-if-present still per-workspace.** `apps/web/biome.json` and `apps/admin/biome.json` are independent. Only skip the workspace that already has the file.

## Context-efficient backpressure (why `run_silent.sh` exists)

Coding agents burn context window tokens reading verbose test / build output. On success, an agent does not need 300 lines of green dots — a single ✓ carries the same signal. On failure, the agent needs the full output to diagnose.

`run_silent.sh` enforces the asymmetry:

```bash
run_silent "typecheck" "bunx tsc --noEmit"
# success:  ✓ typecheck
# failure:  ✗ typecheck
#           <full tsc output>
```

Rule: **success = ✓. failure = full output.**

Use it in CI scripts, composite npm scripts, `verify:silent` targets, and any agent-driven workflow where output lands in a context window. Wrap each distinct check in its own `run_silent` call so failures isolate cleanly.

Source: https://www.humanlayer.dev/blog/context-efficient-backpressure

## Files produced

- `biome.json` — TS/JS linter + formatter
- `[tool.ruff]` block in `pyproject.toml` — Python linter
- `[tool.basedpyright]` block in `pyproject.toml` — Python typecheck
- `.rubocop.yml` + `.rubocop_todo.yml` — Ruby linter
- `knip.json` — only if Knip can't infer from framework
- `lefthook.yml` — hook definitions
- `.github/workflows/baseline.yml` — CI quality gate (only if GitHub remote + no existing workflows)
- `scripts/run_silent.sh` — backpressure wrapper

## Idempotency rule

Light-touch only. For each file above: if it exists, log `already configured: <path>` and move on. Never merge, diff, or overwrite. Re-run safely as the repo grows.

## Resources

- `resources/lefthook.ts.yml` — TS / JS hook template (single package)
- `resources/lefthook.py.yml` — Python hook template (single package)
- `resources/lefthook.rb.yml` — Ruby hook template (single package)
- `resources/github-actions.ts.yml` — CI workflow (single TS package)
- `resources/github-actions.py.yml` — CI workflow (single Python package)
- `resources/github-actions.rb.yml` — CI workflow (single Ruby package)
- `resources/github-actions.monorepo.yml` — CI workflow (multi-workspace base)
- `scripts/run_silent.sh` — backpressure wrapper to drop into target repo
