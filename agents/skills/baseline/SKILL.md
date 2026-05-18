---
name: baseline
description: Install a quality baseline on a repo — linter, formatter, dead-code scanner, lefthook hooks, named local URLs (portless), and a context-efficient backpressure wrapper.
user-invocable: true
---

# Baseline

First-pass guardrails for vibe-coded repos. Detects the stack and framework, installs the standard toolchain with sane defaults, wires git hooks, installs portless for stable local-dev URLs, drops in a backpressure helper for agent-friendly output.

## When to use

- Fresh repo with no linter / formatter / hooks.
- Vibe-coded codebase that needs a quality floor before more work lands.
- Re-running on a repo to fill in missing pieces — checks what exists, installs only what is missing.

## Non-goals

- Does **not** modernize package managers (npm → bun, pip → uv).
- Does **not** reconcile or merge existing configs. If `biome.json`, `lefthook.yml`, `[tool.ruff]` in `pyproject.toml`, etc. already exist, log "already configured" and skip.
- Does **not** enforce custom rules. Tool defaults + framework presets only.

## Toolchain by stack

| Stack   | Package manager | Tools installed                                        |
|---------|-----------------|--------------------------------------------------------|
| TS / JS | `bun`           | `@biomejs/biome`, `fallow`, `lefthook`, `portless` (global) |
| Python  | `uv`            | `ruff`, `basedpyright` (or `pyright`), `lefthook`      |
| Ruby    | `bundler`       | `rubocop` (+ framework gems), `lefthook`               |

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
| Next.js           | `next.config.{js,ts,mjs}` or `next` in deps         | Biome recommended + `nextjs` + `react` domains; Fallow plugin (auto)|
| React Router v7   | `react-router.config.*` or `@react-router/*`        | Biome recommended + `react` domain; Fallow plugin (auto)            |
| Remix             | `remix.config.*` or `@remix-run/*`                  | Biome recommended + `react` domain; Fallow plugin (auto)            |
| Vite              | `vite.config.*`                                     | Biome recommended; Fallow `vite` + `vitest` plugins (auto)          |
| NestJS            | `@nestjs/*` in deps or `nest-cli.json`              | Biome recommended; Fallow `nest` plugin (auto)                      |
| Hono              | `hono` in deps                                      | Biome recommended; Fallow auto-detects via entry points             |
| Astro             | `astro.config.*`                                    | Biome `astro` plugin; Fallow `astro` plugin (auto)                  |
| Bun runtime       | `bun` in deps or `bunfig.toml`                      | Biome recommended; Fallow auto-detects                              |
| Django            | `manage.py` or `django` in deps                     | Ruff preset: `DJ` + `ASYNC` + `B` + `SIM` + `UP` + `I`              |
| FastAPI           | `fastapi` in deps                                   | Ruff preset: `FAST` + `ASYNC` + `B` + `SIM` + `UP` + `I` + `S`      |
| Rails             | `config/application.rb`                             | `rubocop-rails` gem; `require: rubocop-rails` in config             |

Fallow auto-detects most framework plugins from `package.json` — no config needed if a plugin exists. It covers 90+ frameworks (Next, Nuxt, Remix, SvelteKit, Astro, Vite, Vitest, Nest, Storybook, Tailwind, ESLint, TypeScript, etc.).

Biome has first-class `nextjs`/`react`/`test`/`solid` domains in v2+. For NestJS and Hono, Biome recommended is enough — no dedicated domain exists; Fallow handles dead-code detection there.

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

### 4. Install fallow (TS / JS only)

Skip if `fallow.json`, `fallow.jsonc`, `fallow.toml`, or `fallow` key in `package.json` exists. Also skip — and log a migration hint — if an existing `knip.json` / `knip.jsonc` / `.knip.json` or `knip` key in `package.json` is present; suggest the user run `bunx fallow migrate` to convert.

```bash
bun add -d fallow
```

Fallow is a Rust-native codebase analyzer (the same niche as knip, ~3–14× faster, no Node runtime overhead at exec time). It finds unused files, exports, dependencies, types, enum / class members, circular dependencies, duplicate exports, and unresolved imports. It also offers duplication detection (`fallow dupes`) and a complexity report (`fallow health`) — baseline doesn't wire those into hooks by default but they're available.

Fallow auto-detects common frameworks (Next, Nuxt, Remix, Vite, Vitest, Nest, Astro, SvelteKit, Storybook, Tailwind, ESLint, Playwright, Cypress). For Hono and other frameworks without a named plugin, fallow still works via entry-point detection from `package.json` `bin` / `main` / `exports`.

Hook / CI commands use `bunx fallow` (full audit: dead code + duplication + circular deps + complexity). Runs sub-second on most projects and matches the "comprehensive checks on push" principle. Use `bunx fallow dead-code` if a repo needs to scope down (legacy code with high duplication that would flood the report).

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

**Substitute at install time** based on detection (don't ship the raw template if any of these apply):

- **TypeScript typecheck**: remove the tsc step entirely if no `tsconfig.json` exists anywhere in the target (the template already wraps it in `if [ -f tsconfig.json ]`, but for monorepo jobs prefer pruning the step outright).
- **Python typecheck**: detect whether the target uses `basedpyright` or `pyright` (check `pyproject.toml` dev deps). Swap the hook command to match.
- **Ruby test runner**: inspect `Gemfile` for `rspec` / `minitest` / neither, and write `bundle exec rspec`, `bundle exec rake test`, or omit the step accordingly.
- **TS package manager**: if `bun.lockb` absent and `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` present, rewrite every `bun` / `bunx` call to `npm` / `pnpm` / `yarn` equivalents before writing the hook.

### 6. Hook layout

Principle: fast + staged on commit, slow + full-repo on push.

| Tool                 | Pre-commit (staged)       | Pre-push (full)          |
|----------------------|---------------------------|--------------------------|
| Biome                | `--write` staged files    | full repo check          |
| Ruff format + lint   | `format` + `check --fix`  | full repo check          |
| Rubocop              | `-a` staged               | full repo check          |
| Typecheck (tsc)      | —                         | `tsc --noEmit`           |
| Typecheck (basedpyright / pyright) | —           | full project check       |
| Fallow               | —                         | `fallow` (full audit)    |
| Vitest               | `--changed` (if fast)     | full suite               |
| `bun test`           | `--changed` (if fast)     | full suite               |
| Pytest               | —                         | full suite               |
| RSpec / Minitest     | —                         | full suite               |

Rule of thumb: if a staged-files mode exists and the command returns in under a few seconds, move to pre-commit. Otherwise pre-push. Typecheckers, fallow, and full test suites have no staged mode → always pre-push.

### 7. Drop in the backpressure wrapper

Copy `scripts/run_silent.sh` into the target repo at `scripts/run_silent.sh` (create dir if missing). `chmod +x scripts/run_silent.sh`.

Skip if the file already exists.

**Make it discoverable to agents.** Append the pointer snippet from `resources/agent-instructions.snippet.md` to any of these files that already exist at the target repo root:

- `CLAUDE.md` (Claude Code)
- `AGENTS.md` (Codex, OpenCode, and the emerging cross-agent convention)
- `.cursor/rules/*.mdc` (Cursor) — only if the user already uses rules

Skip append if the target file already contains the string `run_silent.sh` (idempotent). Do **not** create `CLAUDE.md` / `AGENTS.md` from scratch — only append when one already exists; otherwise the repo may not have opted in to agent instructions.

**TS / JS only — also append the portless snippet** from `resources/agent-instructions.portless.snippet.md` to the same files. This adds the `portless` dev-server invocation and the docker-alias recipe. Idempotency string: `portless`. Skip on Python / Ruby repos — they don't have portless installed and `package.json` references would be invalid.

Why: the wrapper is invisible unless agents know to use it. Putting a short pointer in the target repo's agent-instructions file means any agent that reads them (Claude Code, Codex, OpenCode, Cursor) discovers the helper on first pass.

### 8. Install portless (TS / JS only — runtime ports)

Portless replaces `localhost:<random-port>` with stable `https://<project>.localhost` URLs for local dev. It runs an HTTPS reverse proxy and auto-discovers the `"dev"` script in `package.json`, so package.json scripts stay clean — no `dev:portless` alias.

**Why we install it by default:**

- Stable URL across restarts → cookies, `localStorage`, OAuth redirect URIs, CORS allowlists, and `.env` files don't break when ports shuffle.
- Deterministic for AI agents — `https://myapp.localhost` is unambiguous, while "I think the server is on 3000? or 3001?" is not.
- Git worktrees get auto-prefixed subdomains (`fix-ui.myapp.localhost`) with zero config. Each worktree is independently addressable.
- Auto-injects `PORT` into the child process; for frameworks that ignore `PORT` (Vite, Astro, React Router, Angular, Expo, RN), portless injects `--port` and `--host` correctly.
- HTTPS by default with a locally-trusted CA — first run does `portless trust` automatically (sudo on macOS / Linux for port 443).

**Skip condition**: `portless` is already on `$PATH` (`command -v portless`) **and** the user's shell history or `package.json` shows it in use. Otherwise:

```bash
bun add -g portless           # global; recommended in the portless docs
portless trust                # one-time: trust the local CA
```

If global install isn't acceptable for some reason (corporate dev container, locked-down host), fall back to `bun add -D portless` and run via `bunx portless`.

**Do not rewrite `package.json`.** Keep `"dev": "next dev"` (or whatever it is) as-is. Portless reads that script and proxies it. The change is to the **invocation**: run `portless` instead of `bun run dev`. The TS/JS-only portless snippet appended in step 7 (`resources/agent-instructions.portless.snippet.md`) tells agents to do exactly that.

**Docker compatibility.** Portless works alongside Docker. For each published container port, register a static route once:

```bash
docker run -d -p 5432:5432 postgres:16
portless alias db 5432              # -> https://db.localhost
portless alias --remove db          # to undo
```

Aliases persist across stale-route cleanup, so they survive proxy restarts. For Docker Compose stacks, drop a small `scripts/portless-aliases.sh` that runs `portless alias` for each container after `docker compose up -d`. Don't auto-generate this file from the skill — leave it to the user since the alias names are project-specific.

**Pre-1.0 caveat.** Portless is pre-1.0 and the state directory format can change between releases. If a contributor's `portless trust` warning appears after an upgrade, re-run it. Log a single-line note about this when installing.

### 9. GitHub Actions (quality gate)

Only runs if the remote is GitHub. Check:

```bash
git remote get-url origin 2>/dev/null | grep -q github.com
```

Skip condition: if **any** file exists under `.github/workflows/` → log `GitHub Actions already configured, skipping.` Do not overwrite or merge. User opted in manually or via a different skill.

If no workflows exist → write `.github/workflows/ci.yml` using the matching template from `resources/github-actions.*.yml`. The workflow's `name:` is `CI` (the conventional OSS name — what GitHub displays in the Actions tab and on PR checks), not `baseline`.

**Scope of the workflow: full quality suite for every detected workspace, not just tools this skill installed.** If the repo already has vitest, playwright, pytest, basedpyright, etc., include them. Detect by scanning:

- `package.json` scripts (`test`, `test:e2e`, `typecheck`, `lint`) and deps
- `pyproject.toml` deps (pytest, basedpyright, pyright, mypy, ruff)
- `Gemfile` (rspec, minitest, rubocop)

Build the workflow from detected tools — lint + format-check + typecheck + dead-code + unit tests + e2e tests, per workspace. Mirror pre-push hook commands so local and CI stay in sync.

**Monorepo**: use `resources/github-actions.monorepo.yml` as a base; add one job per workspace with `defaults.run.working-directory` scoped to the package path. Each job runs its own full suite — lint, typecheck, dead-code, tests. Don't share steps across stacks (TS and Py need different setup actions).

**Runners**: `ubuntu-latest`. **Triggers**: `pull_request` + `push` to default branch only (not every push — prevents duplicate runs on PRs).

**Detect the default branch** at install time:

```bash
git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|origin/||'
```

Substitute the result into `branches: [<detected>]` before writing the workflow. Don't ship `main` if the remote default is `master` / `trunk` / something else.

**Package manager substitution** for the TS workflow: same rule as lefthook — detect via lockfile, rewrite `bun install` + setup action to the match (`npm ci` + `actions/setup-node@v4`, `pnpm install --frozen-lockfile` + `pnpm/action-setup@v4`, etc.). Templates carry inline comments showing the swaps.

**Python typecheck substitution**: same basedpyright ↔ pyright rule. **Ruby test runner substitution**: same rspec ↔ rake test rule.

**Caching**: `astral-sh/setup-uv@v5` and `oven-sh/setup-bun@v2` handle caching via their own flags. Don't hand-roll `actions/cache`.

### 10. Verify

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

4. **Pre-push: run each workspace's own suite.** One command per workspace for typecheck / fallow / tests, so failures isolate:

    ```yaml
    pre-push:
      commands:
        typecheck-web:
          run: cd apps/web && bunx tsc --noEmit
        fallow-web:
          run: cd apps/web && bunx fallow
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
- `fallow.json` — only if fallow can't infer from framework
- `lefthook.yml` — hook definitions
- `.github/workflows/ci.yml` — CI quality gate (only if GitHub remote + no existing workflows; workflow `name: CI`)
- `scripts/run_silent.sh` — backpressure wrapper
- portless is installed **globally** (`bun add -g portless`), not in the repo, so it produces no project file. `portless.json` is opt-in only when the user wants to override the inferred app name.

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
- `resources/agent-instructions.snippet.md` — pointer appended to target repo's `CLAUDE.md` / `AGENTS.md` so agents discover `run_silent.sh` (all stacks)
- `resources/agent-instructions.portless.snippet.md` — portless dev-server + docker-alias guidance, appended only on TS / JS repos
- `scripts/run_silent.sh` — backpressure wrapper to drop into target repo
