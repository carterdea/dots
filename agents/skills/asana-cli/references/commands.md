# Asana CLI — Full Command Reference

Authoritative list of every `asana` command, its arguments, and options (v0.5.0).
When in doubt about a flag, run `asana <command> --help` — per-command help is accurate.

Conventions: `<required>`, `[optional]`. Most write commands print the created/updated
object including its `gid` and `permalink_url`.

## Table of contents

- [Global options](#global-options)
- [fetch](#fetch) — resolve an app.asana.com URL to its task/project/comment
- [auth](#auth) — login / logout / whoami
- [workspace](#workspace)
- [task](#task) — create / list / get / update / move / complete / delete
- [task subtask](#task-subtask)
- [task dependency / dependent](#task-dependency--dependent)
- [task comment](#task-comment)
- [task follower](#task-follower)
- [task tag](#task-tag)
- [task attachments](#task-attachments)
- [task custom-field](#task-custom-field)
- [task batch operations](#task-batch-operations)
- [project](#project)
- [section](#section)
- [tag](#tag)
- [custom-field](#custom-field-definitions)
- [search](#search)
- [team](#team)
- [user](#user)
- [self-update](#self-update)
- [config, auth, env details](#configuration--authentication-details)

---

## Global options

`asana [-f|--format <type>] <command>`

- `-f, --format <type>` — `toon` (default, token-efficient for LLMs), `json` (scripting), `plain` (human tables)

---

## fetch

- `asana fetch <url>` — resolve an `app.asana.com` URL to its underlying resource and fetch it. Pass a pasted Asana link verbatim instead of extracting the gid and choosing a subcommand.
  - A task URL (V0 `…/0/{project}/{task}` or V1 `…/1/{ws}/task/{task}`, with or without a trailing `/f` focus suffix) → the task (same output as `task get`).
  - A project URL → the project (same as `project get`).
  - A comment URL (`…/task/{task}/comment/{comment}`) → that task's comment list (same as `task comment list`; there is no single-comment fetch).
  - An unrecognized or non-Asana URL → `INVALID_ASANA_URL` error, exit 1.

---

## auth

- `asana auth login` — login via OAuth or PAT
  - `--token <token>` — use Personal Access Token (recommended; from https://app.asana.com/0/my-apps)
  - `-w, --workspace <workspace>` — set default workspace at login
  - `--scope <scopes>` — OAuth scopes, space-separated
  - `--no-browser` — copy-paste flow for headless/CI
- `asana auth logout` — remove stored credentials
- `asana auth whoami` — show current user, auth type, default workspace

OAuth requires env vars `ASANA_CLIENT_ID` and `ASANA_CLIENT_SECRET`.

## workspace

- `asana workspace list` — list workspaces `[--no-cache]`
- `asana workspace get <gid>` — workspace details
- `asana workspace users [gid]` — list users (defaults to configured workspace)
- `asana workspace set-default <gid>` — persist default workspace to config

## task

- `asana task create` — create a task
  - `-n, --name <name>` (required)
  - `-d, --notes <notes>`
  - `-a, --assignee <assignee>` — user GID
  - `--due-on <date>` — YYYY-MM-DD (canonical; `--due` is a deprecated alias)
  - `-w, --workspace <workspace>`
  - `-p, --project <project>`
- `asana task list` — list tasks (needs at least one of workspace/project/assignee)
  - `-a, --assignee <assignee>` — `me` for current user
  - `-w, --workspace <workspace>`
  - `-p, --project <project>`
  - `-c, --completed` — include completed (excluded by default)
- `asana task get <gid>` — full details
- `asana task update <gid>` — update fields
  - `-n, --name <name>`
  - `-d, --notes <notes>`
  - `-a, --assignee <assignee>`
  - `--due-on <date>` — YYYY-MM-DD
  - `--start-on <date>` — YYYY-MM-DD
  - `-c, --completed <boolean>` — `true`/`false`
- `asana task move <gid>` — move to another project
  - `-p, --project <project>` (required)
  - `-s, --section <section>`
- `asana task complete <gid>` — mark complete
- `asana task delete <gid>` — permanently delete (destructive)

## task subtask

- `asana task subtask list <parent-gid>` `[-r|--recursive]`
- `asana task subtask create <parent-gid>`
  - `-n, --name <name>` (required), `-d, --notes`, `-a, --assignee`, `--due-on <date>`
- `asana task subtask add <task-gid> <parent-gid>` — convert existing task into a subtask

## task dependency / dependent

- `asana task dependency add <task-gid> <depends-on-gid>` — task is blocked by depends-on
- `asana task dependency remove <task-gid> <depends-on-gid>`
- `asana task dependency list <task-gid>` — tasks that block this one
- `asana task dependent list <task-gid>` — tasks blocked by this one

Asana caps combined dependencies + dependents at 50.

## task comment

- `asana task comment add <task-gid> <text>` `[--html]` (rich text; auto-wraps in `<body>`)
- `asana task comment list <task-gid>` — user comments only (excludes system events)

## task follower

- `asana task follower add <task-gid> <user-gid>` — user GID, email, or `me`
- `asana task follower remove <task-gid> <user-gid>`
- `asana task follower list <task-gid>`

## task tag

- `asana task tag add <task-gid> <tag-gid>`
- `asana task tag remove <task-gid> <tag-gid>`
- `asana task tag list <task-gid>`

## task attachments

- `asana task attach <task-gid> <file>` — upload a local file (streamed)
- `asana task attachment list <task-gid>`
- `asana task attachment download <attachment-gid>` `[-o|--output <path>] [--force]`
  - External attachments (e.g. Google Drive links) cannot be downloaded.

## task custom-field

- `asana task custom-field set <task-gid> <field-gid> <value>` — value coerced to field type (text/number/enum name or gid)
- `asana task custom-field list <task-gid>`

## task batch operations

- `asana task batch-create --file <path>` `[-w|--workspace <gid>]`
  - JSON array of task objects (`name` required), or CSV with header row (`name`, optional `notes`/`assignee`/`due_on`/`completed`/`project`).
- `asana task batch-update --file <path>`
  - JSON array of `{gid, ...fields}` or `{"tasks":[...]}`. Each record needs `gid`.
- `asana task batch-delete --file <path>` `[--yes]` (destructive)
  - Text file, one GID per line; `#` lines are comments. Prompts unless `--yes`.

All batch commands print a summary: total / succeeded / failed (+ failure details).

## project

- `asana project create`
  - `-n, --name <name>` (required), `-w, --workspace`, `-t, --team`, `-d, --notes`, `--color <color>`, `--public`
- `asana project list` — needs workspace or team `[-w] [-t] [-a|--archived]`
- `asana project get <gid>`
- `asana project update <gid>`
  - `-n, --name`, `-d, --notes`, `--color <color>`, `--archived <boolean>`, `--public <boolean>`
- `asana project delete <gid>` (destructive)

## section

- `asana section list <project-gid>`
- `asana section create <project-gid>`
  - `-n, --name <name>` (required), `--insert-before <section-gid>`, `--insert-after <section-gid>`
- `asana section update <section-gid>` `-n, --name <name>`
- `asana section delete <section-gid>` (destructive)

## tag

- `asana tag list` `[-w|--workspace]`
- `asana tag create`
  - `-n, --name <name>` (required), `-w, --workspace`, `-c, --color <color>` (e.g. `dark-red`), `-d, --notes`
- `asana tag get <tag-gid>`
- `asana tag update <tag-gid>` `-n, --name`, `-c, --color`, `-d, --notes` (≥1 required)
- `asana tag delete <tag-gid>` (destructive)

## custom-field definitions

- `asana custom-field list` `[-w|--workspace]` — workspace's custom field definitions (gid/name/type)

## search

- `asana search tasks <query>` — full-text search (premium workspaces only)
  - `-w, --workspace`, `-l, --limit <1-100>` (default 20), `-c, --completed <true|false>`, `-a, --assignee <gids,comma-separated>`
- `asana search projects <query>` — typeahead project name search
  - `-w, --workspace`, `-l, --limit <1-100>` (default 20)

## team

- `asana team list` `[-w|--workspace] [--no-cache]`
- `asana team get <gid>`
- `asana team members <gid>`

## user

- `asana user me` — current user
- `asana user get <user>` — GID, email, or `me`
- `asana user search <query>` — fuzzy match by name/email `[-w|--workspace]`
- `asana user tasks <user>` — tasks assigned to user `[-w|--workspace] [-c|--completed]`

## self-update

- `asana self-update` `[--check]` — update CLI to latest (use `brew upgrade asana-cli` if installed via Homebrew)

---

## Configuration & authentication details

**Config file:** `~/.asana-cli/config.json` — stores `accessToken`, `refreshToken` (OAuth),
`authType` (`pat`/`oauth`), `workspace` (default), `expiresAt`, `scopes`.

**Environment variables (override config):**

- `ASANA_ACCESS_TOKEN` — PAT; used instead of config file if set
- `ASANA_WORKSPACE` — default workspace GID
- `ASANA_CLIENT_ID` / `ASANA_CLIENT_SECRET` — OAuth app credentials (for `auth login` OAuth flow)

**Workspace resolution priority:** `-w` option → config default → `ASANA_WORKSPACE`.
If none set, commands needing a workspace fail with:
`"Workspace is required. Set default workspace or use -w option."`

## Gotchas

1. GIDs must be numeric strings. User-identifying args also accept `me` and (for followers/users) email.
2. Dates are strict `YYYY-MM-DD`.
3. `task move` removes the task from all current projects before adding the target.
4. `search tasks` is a premium-only Asana feature; on free workspaces it errors.
5. `workspace list` and `team list` cache results — use `--no-cache` for fresh data.
6. Boolean update flags take an explicit value: `task update <gid> -c true`.
7. Names are NOT resolved to GIDs automatically. Find the GID first (list/search/user search), then act.
