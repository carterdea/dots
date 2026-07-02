# GitHub Actions And Monorepos Reference

Use this when adding CI or when more than one workspace/stack is detected.

## GitHub Actions

Only add CI when the remote is GitHub:

```bash
git remote get-url origin 2>/dev/null | grep -q github.com
```

Skip condition: if any file exists under `.github/workflows/`, log `GitHub Actions already configured, skipping.` Do not overwrite or merge.

If no workflows exist, write `.github/workflows/ci.yml` from the matching resource template. The workflow name is `CI`.

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

For Python, use `astral-sh/setup-uv@v5`. Swap basedpyright/pyright based on the repo.

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
      glob: "apps/web/**/*.{ts,tsx,js,jsx,json}"
      run: cd apps/web && bunx biome check --write {staged_files}
      stage_fixed: true
    ruff-chat:
      glob: "chat-services/**/*.py"
      run: cd chat-services && uv run ruff check --fix {staged_files}
      stage_fixed: true

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

For GitHub Actions monorepos, use `resources/github-actions.monorepo.yml` as a base and add one job per workspace with `defaults.run.working-directory`.
