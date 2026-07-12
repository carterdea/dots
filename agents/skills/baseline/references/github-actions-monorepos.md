# GitHub Actions And Monorepos Reference

Use this when adding CI or when more than one workspace/stack is detected.

## GitHub Actions

Only add CI when the remote is GitHub:

```bash
git remote get-url origin 2>/dev/null | grep -q github.com
```

Skip condition: if any file exists under `.github/workflows/`, log `GitHub Actions already configured, skipping.` Do not overwrite or merge.

If no workflows exist, write `.github/workflows/ci.yml` from the matching resource template. The workflow name is `CI`.

Job shape — always one job per check:

- Every check (lint, typecheck, dead-code, each test suite) is its own job, so it appears as its own PR status check and a failure points at exactly one thing. Never lump checks into steps of a single job or behind an aggregate script like `npm run check`.
- Name jobs after the check (`lint`, `typecheck`, `test`); in monorepos prefix the workspace (`web-lint`, `api-test`).
- Duplicating checkout/setup/install across jobs is expected and fine; setup actions cache, so overhead stays small.
- Add one test job per suite that actually exists (unit, integration, e2e/playwright). Never add a job for a suite the repo doesn't have yet.
- Attach service containers (Postgres, Redis) only to the jobs that need them.
- Include a `concurrency` block keyed on workflow + ref with `cancel-in-progress: true` so superseded runs stop.
- If the repo's manifest already defines per-check scripts (`lint`, `typecheck`, `test`), have each job call those instead of raw tool commands — the repo stays the source of truth for what a check means.

The workflow should run the full detected suite for every workspace, not only tools this skill installed. Detect:

- `package.json` scripts and deps: `test`, `test:e2e`, `typecheck`, `lint`, vitest, playwright.
- `pyproject.toml` deps: pytest, basedpyright, pyright, mypy, ruff.
- `Gemfile`: rspec, minitest, rubocop.

Triggers: `pull_request` and `push` to the detected default branch only.

Detect default branch:

```bash
git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|origin/||'
```

Substitute the result into `branches: [<detected>]`; do not assume `main`.

For TS package manager substitution, mirror lefthook:

- Bun: `bun install` with `oven-sh/setup-bun@v2`.
- npm: `npm ci` with `actions/setup-node@v4`.
- pnpm: `pnpm install --frozen-lockfile` with `pnpm/action-setup@v4` plus `actions/setup-node@v4`.
- yarn: use the repo's lockfile-compatible install command.

For Python package-manager substitution, mirror the detected project manager:

- uv: `astral-sh/setup-uv@v5`, `uv sync --all-extras --dev`, and `uv run <tool>`.
- Poetry: `actions/setup-python@v5`, install the Poetry version expected by the repo, `poetry install --with dev`, and `poetry run <tool>`.
- pip / requirements: `actions/setup-python@v5`, `python -m pip install -r requirements.txt` plus any missing dev-tool requirements the repo expects, and direct tool commands such as `ruff check .` or `pytest`.

Swap basedpyright/pyright based on the repo.

For Ruby, choose RSpec or Minitest based on `Gemfile`.

Do not hand-roll `actions/cache`; setup actions handle their own caching.

## Monorepos

Common layouts:

- TS workspaces: `apps/web`, `packages/ui`, one root lockfile.
- Mixed stacks: frontend plus Python service, Ruby app, etc.
- Turborepo/Nx: workspace manifests plus task runner.

Rules:

1. Keep one root `lefthook.yml`.
2. Install linter/formatter per workspace with its own manifest.
3. Scope pre-commit globs to each workspace.
4. Run one pre-push command per workspace suite so failures isolate.
5. Apply skip-if-present per workspace, not globally.

Example hook shape:

```yaml
pre-commit:
  commands:
    biome-web:
      root: "apps/web/"
      glob: "**/*.{ts,tsx,js,jsx,json}"
      run: bunx biome check --write {staged_files}
      stage_fixed: true
    ruff-chat:
      root: "chat-services/"
      glob: "**/*.py"
      run: uv run ruff check --fix {staged_files}
      stage_fixed: true

pre-push:
  commands:
    typecheck-web:
      root: "apps/web/"
      run: bunx tsc --noEmit
    fallow-web:
      root: "apps/web/"
      run: bunx fallow
    test-web:
      root: "apps/web/"
      run: bun run test
    pytest-chat:
      root: "chat-services/"
      run: uv run pytest
```

For GitHub Actions monorepos, use `resources/github-actions.monorepo.yml` as a base and add one job per check per workspace (`web-lint`, `web-test`, `api-test`, …) with `defaults.run.working-directory`.
