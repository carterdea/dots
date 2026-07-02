# Theme Access And Ignore Files

Use this when `shopify.theme.toml` exists or the repo otherwise uses Shopify CLI theme commands.

## Theme Access Token

Theme commands authenticate interactively or with a Theme Access password (`shptka_...`). Scripted commands use `SHOPIFY_CLI_THEME_TOKEN`.

- Never commit the token.
- If `shopify.theme.toml` or any committed file contains `password = "shptka_..."`, treat it as leaked. Move the value into `.env`, delete only the password line, and tell the user to rotate it in the Theme Access app.
- Before writing a token, check whether `.env` is tracked. If `git ls-files --error-unmatch .env` succeeds, run `git rm --cached .env` first and warn that any committed secret needs rotation.
- One environment, or all environments sharing one store/token: write `SHOPIFY_CLI_THEME_TOKEN=shptka_...` to `.env`.
- Multiple environments with distinct stores/tokens: do not collapse them into one token. Use environment-specific keys such as `SHOPIFY_CLI_THEME_TOKEN_STAGING` and select per command with `--password "$SHOPIFY_CLI_THEME_TOKEN_STAGING"`.
- Never invent a token. If none exists, write only `.env.example` and tell the user to create one in Theme Access.
- Shopify CLI does not auto-load `.env`; tell the user to load it with direnv or `set -a; source .env; set +a`, and to add masked CI secrets.

## `.env.example` And `.gitignore`

Write `.env.example` from `resources/env.shopify.example` when missing.

Append these ignore rules if missing:

```gitignore
test-results/
/qa/screenshots/
/qa/reports/
.env
.env.*
!.env.example
```

Git uses the last matching pattern, so `!.env.example` must come after every `.env` / `.env.*` rule. If the exception already exists but new env ignore rules are appended after it, re-append the exception after the new rules.

Ignore concrete QA artifact subdirectories, not all of `qa/`.

## `.shopifyignore`

`.shopifyignore` is bidirectional: it blocks both push and pull.

- Write `resources/shopifyignore.default` when missing.
- Reconcile existing `.shopifyignore`; do not clobber it.
- Defaults include `assets/*.map` and `*.DS_Store`.
- Do not default-ignore `config/settings_data.json`, because that would block pulling merchant customizer settings.
- To avoid clobbering merchant settings during push, pass `--ignore config/settings_data.json` on the push command.
- Keep `config/settings_schema.json` and `locales/*.json` tracked.

When the repo root is also the theme root, defensively exclude repo tooling and source such as `node_modules/`, `src/`, `scripts/`, `.github/`, lockfiles, and configs so the Shopify CLI does not push them to the theme.
