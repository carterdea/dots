# Stack Reference

Use this only after `SKILL.md` detects the stack or workspace that needs it.

## Toolchain By Stack

| Stack | Package manager | Tools installed |
| --- | --- | --- |
| TS / JS | `bun` by default | `@biomejs/biome`, `fallow`, `lefthook` |
| Python | `uv` by default | `ruff`, `basedpyright` or `pyright`, `lefthook` |
| Ruby | `bundler` | `rubocop` plus framework gems, `lefthook` |
| All | n/a, global | `portless` |

If a repo already uses npm, pnpm, yarn, pip, poetry, or another manager, fall back to that manager's idiomatic install command. Do not rewrite lockfiles.

## Framework Detection

| Framework | Marker | Preset |
| --- | --- | --- |
| Next.js | `next.config.{js,ts,mjs}` or `next` in deps | Biome recommended plus Next/React domains; Fallow auto plugin |
| React Router v7 | `react-router.config.*` or `@react-router/*` | Biome recommended plus React domain; Fallow auto plugin |
| Remix | `remix.config.*` or `@remix-run/*` | Biome recommended plus React domain; Fallow auto plugin |
| Vite | `vite.config.*` | Biome recommended; Fallow `vite` and `vitest` plugins |
| NestJS | `@nestjs/*` in deps or `nest-cli.json` | Biome recommended; Fallow `nest` plugin |
| Hono | `hono` in deps | Biome recommended; Fallow auto-detects entry points |
| Astro | `astro.config.*` | Biome Astro plugin; Fallow `astro` plugin |
| Bun runtime | `bun` in deps or `bunfig.toml` | Biome recommended; Fallow auto-detects |
| Django | `manage.py` or `django` in deps | Ruff `DJ`, `ASYNC`, `B`, `SIM`, `UP`, `I` |
| FastAPI | `fastapi` in deps | Ruff `FAST`, `ASYNC`, `B`, `SIM`, `UP`, `I`, `S` |
| Rails | `config/application.rb` | `rubocop-rails` and `require: rubocop-rails` |

Fallow auto-detects framework plugins from `package.json`; no config is needed when a plugin exists. Biome has first-class domains for common JS frameworks in v2+.

## TS / JS

Skip Biome if `biome.json` or `biome.jsonc` exists.

```bash
bun add -d --exact @biomejs/biome
bunx biome init
```

Baseline `biome.json` after init:

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

For Next.js, React, Remix, or React Router, add globals as needed and enable the matching domains per current Biome docs.

## Python

Skip Ruff if `[tool.ruff]` is present in `pyproject.toml` or `ruff.toml` exists.

```bash
uv add --dev ruff
```

Ruff selector prefixes:

| Prefix | What it catches |
| --- | --- |
| `F` | pyflakes: unused imports, undefined names |
| `E` / `W` | pycodestyle |
| `I` | import ordering |
| `B` | flake8-bugbear likely bugs |
| `SIM` | simpler constructs |
| `UP` | modern syntax |
| `S` | security |
| `ASYNC` | async footguns |
| `FAST` | FastAPI anti-patterns |
| `DJ` | Django anti-patterns |
| `PT` | pytest idioms |

Baseline config:

```toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
extend-select = ["I", "B", "SIM", "UP", "ASYNC", "PT"]
```

FastAPI:

```toml
[tool.ruff.lint]
extend-select = ["I", "B", "SIM", "UP", "ASYNC", "PT", "FAST", "S"]
ignore = ["S101"]
```

Django:

```toml
[tool.ruff.lint]
extend-select = ["I", "B", "SIM", "UP", "ASYNC", "PT", "DJ"]
```

Install `basedpyright` unless the repo already uses `pyright`.

```bash
uv add --dev basedpyright
```

Minimal config:

```toml
[tool.basedpyright]
typeCheckingMode = "standard"
```

## Ruby

Skip if `.rubocop.yml` exists.

```bash
bundle add rubocop --group=development,test
```

Only when Rails is detected, install Rails cops before generating the baseline:

```bash
bundle add rubocop-rails --group=development,test
```

Then generate the baseline:

```bash
bundle exec rubocop --auto-gen-config
```

`--auto-gen-config` writes `.rubocop_todo.yml`; include it from `.rubocop.yml` so legacy code does not block commits immediately.

## Fallow

TS / JS only. Skip if `fallow.json`, `fallow.jsonc`, `fallow.toml`, or a `fallow` key in `package.json` exists.

```bash
bun add -d fallow
```

Install fallow even when a `knip` config exists because hooks and CI call `bunx fallow`. Log a hint to run `bunx fallow migrate`, but leave knip in place.

Use `bunx fallow` for the full audit. Use `bunx fallow dead-code` when a legacy repo would flood the report.

## Lefthook

Skip if `lefthook.yml`, `lefthook.yaml`, or `.lefthook.yml` exists at repo root.

```bash
# TS / JS
bun add -d lefthook
bunx lefthook install

# Python
uv add --dev lefthook
uv run lefthook install

# Ruby
bundle add lefthook --group=development
bundle exec lefthook install
```

Copy the matching template from `resources/` to `lefthook.yml`. Substitute before writing:

- Remove TypeScript typecheck if no `tsconfig.json` exists anywhere in the target.
- Swap Python typecheck to `basedpyright` or `pyright` based on existing dev deps.
- Use `bundle exec rspec`, `bundle exec rake test`, or omit the Ruby test step based on `Gemfile`.
- If TS is not using Bun, rewrite `bun` / `bunx` calls to the existing manager equivalent.

Hook layout:

| Tool | Pre-commit | Pre-push |
| --- | --- | --- |
| Biome | `--write` staged files | full repo check |
| Ruff | `format` and `check --fix` | full repo check |
| Rubocop | `-a` staged | full repo check |
| Typecheck | none | full project check |
| Fallow | none | full audit |
| Tests | changed/staged only if fast | full relevant suite |

Typecheckers, fallow, and full suites have no useful staged mode, so keep them pre-push.
