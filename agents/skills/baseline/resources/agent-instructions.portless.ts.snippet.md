<!-- baseline:portless:ts -->
## Local dev server

Start the dev server with `portless` — not `bun run dev` / `npm run dev`. Portless reads the `"dev"` script from `package.json` and serves it on a stable `https://<project>.localhost` URL behind an HTTPS reverse proxy. Git worktrees automatically get a branch-prefixed subdomain (e.g. `fix-ui.<project>.localhost`).

```bash
portless          # runs the package.json "dev" script through the proxy
portless list     # show active routes
```

**Monorepos**: bare `portless` run from a workspace root (detected via `pnpm-workspace.yaml` or `package.json` `"workspaces"`) starts **every** workspace package that has a `dev` script. To start just one app, either `cd` into the workspace first, or invoke it by name with an explicit command:

```bash
cd apps/web && portless
# or
portless web bunx next dev          # explicit name + command
```

Why: stable named URL, no port collisions, deterministic for agents (no guessing `:3000` vs `:3001`), cookies and `localStorage` scoped per app, OAuth / CORS / `.env` URLs stay stable across restarts.

**Docker services**: register published ports with `portless alias <name> <port>` so containers participate in the same `.localhost` scheme.

```bash
docker run -d -p 5432:5432 postgres:16
portless alias db 5432    # -> https://db.localhost
```
