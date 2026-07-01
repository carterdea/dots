---
name: asana-cli
description: >-
  Manage Asana (아사나) from the terminal with the `asana` CLI — tasks, projects,
  sections, subtasks, comments, dependencies, followers, tags, attachments,
  custom fields, CSV/JSON batch import, and workspace/team/user lookups. Use
  this whenever the user wants to create, list, find, count, update, complete,
  assign, or delete Asana tasks or projects; add a comment, subtask, due date,
  or follower; pull their Asana to-do list; or import tasks from a file into
  Asana — even when they only say "Asana"/"아사나", paste an app.asana.com task
  or project link, or describe work they want tracked there without naming the
  CLI. (Does not apply to writing Asana API/SDK code or editing the asana CLI's
  own source — only to operating Asana through the CLI.)
---

# Asana CLI

`asana` is a command-line tool for Asana, powered by Bun. It speaks the same
objects as Asana's web app — tasks, projects, sections, tags, users — addressed
by their numeric `gid`. This skill is about driving it efficiently and safely.

## Auth and workspace: act first, recover on error

In a working setup the CLI is already logged in with a default workspace, so
just run the command the user asked for — don't spend a turn on `auth whoami`
"to be safe". Only fall back to diagnosis when a command actually fails:

- **`✗ Not authenticated` / token error** → tell the user to run
  `asana auth login --token <PAT>` (token from https://app.asana.com/0/my-apps).
  Don't log in for them — it needs their secret. (OAuth via `asana auth login`
  needs `ASANA_CLIENT_ID`/`ASANA_CLIENT_SECRET` env vars and a browser.)
- **`Workspace is required …`** → run `asana workspace list`, then either pass
  `-w <gid>` on the command or set it once with `asana workspace set-default <gid>`.

Workspace resolution order: `-w` flag → config default → `ASANA_WORKSPACE` env
var. `asana auth whoami` is the right tool to _confirm who you are or which
workspace is default_ — reach for it when that's genuinely in question, not as a
reflex before every command.

## Output format: keep it `toon`, switch to `json` to parse

The default `toon` format is compact and easy to read — leave it as-is when you
just need to see results. Add `--format json` (or `-f json`) **only when you
need to extract a `gid` or field programmatically** (piping to `jq`, looping).
Avoid `--format plain` unless the user explicitly wants the traditional view; it
carries the least information per token.

```bash
asana task list -a me                                   # read it yourself (toon)
asana task get 1207891234567890 -f json | jq -r '.task.gid'   # parse a field
```

## The golden rule: resolve names to GIDs first

The CLI does **not** look names up for you. A task, project, user, or tag is
referenced by its numeric `gid`. When the user names something instead of giving
a gid ("move the login bug to the Q3 board"), find the gid first, then act:

| User says…                 | Resolve with                                                         |
| -------------------------- | -------------------------------------------------------------------- |
| a person ("assign to Jin") | `asana user search "Jin"` → user gid (or just use `me`)              |
| a project ("the Q3 board") | `asana search projects "Q3"` or `asana project list -w <gid>`        |
| a task ("the login bug")   | `asana search tasks "login"` (premium) or `asana task list -p <gid>` |
| a tag, section, team       | `asana tag list` / `asana section list <proj>` / `asana team list`   |

Chain it in one shot when you're confident, e.g.:

```bash
PROJ=$(asana search projects "Q3 roadmap" -f json | jq -r '.projects[0].gid')
asana task create -n "Ship release notes" -p "$PROJ" --due-on 2026-07-01
```

If a lookup returns several plausible matches, show them to the user and ask
which one rather than guessing — acting on the wrong gid is the main failure mode.

## Common workflows

```bash
# My open tasks (current user, default workspace)
asana task list -a me

# Create a task in a project, assigned to me, with a due date
# (the due-date flag is --due-on, same as `task update`; change it later with
#  `asana task update <gid> --due-on <date>`)
asana task create -n "Fix login redirect" -p 12345 -a me --due-on 2026-07-01

# Look at a task someone linked (the trailing number in an Asana URL IS the gid)
asana task get 1207891234567890

# Add a comment, then complete it
asana task comment add 1207891234567890 "Fixed in PR #482"
asana task complete 1207891234567890

# Break work down
asana task subtask create 1207891234567890 -n "Write regression test"

# Bulk import from a spreadsheet export
asana task batch-create --file ./new-tasks.csv -w 12345
```

An Asana task/project URL like `https://app.asana.com/0/12345/1207891234567890`
ends in the resource gid — pull it straight out instead of searching.

## Safety: confirm before destroying

`delete` (task/project/section/tag) and `batch-delete` are permanent — Asana has
no undo. Before running any delete, confirm with the user what will be removed,
and prefer `asana task complete` over `delete` when the user just means "I'm done
with this." For `batch-delete`, review the GID file first and keep the
confirmation prompt (don't reach for `--yes` unless the user explicitly asked to
skip it).

## Full command reference

This covers the common path. For the complete list of commands, every flag,
batch-file formats, custom fields, dependencies, search filters, and config/auth
details, read `references/commands.md`. You can also trust `asana <command> --help`
for any specific command's options.
