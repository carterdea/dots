## Local dev server

Start the dev server through `portless` so it gets a stable `https://<project>.localhost` URL. Pass the command explicitly — Python frameworks don't have a zero-arg `portless` mode like JS does, because there's no `package.json` "dev" script for portless to read.

```bash
# FastAPI / Uvicorn
portless run uv run uvicorn app.main:app --port $PORT --host 127.0.0.1

# Django
portless run uv run python manage.py runserver 0.0.0.0:$PORT

# Flask
portless run uv run flask --app app run --port $PORT --host 127.0.0.1
```

Portless injects `PORT=<random 4000–4999>` and `HOST=127.0.0.1` into the child process. Pass `$PORT` explicitly on the command line — Python servers don't read it from the environment by default.

In git worktrees, the branch name is auto-prefixed (e.g. `fix-api.<project>.localhost`). Each worktree gets its own URL with no config.

**Hardcoded-port servers**: if the server can't accept a port flag, start it on its fixed port and register a static route once:

```bash
portless alias myapp 8000    # -> https://myapp.localhost
```

**Docker services**: same pattern. Register published ports so containers share the `.localhost` scheme:

```bash
docker run -d -p 5432:5432 postgres:16
portless alias db 5432       # -> https://db.localhost
```
