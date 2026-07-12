---
name: trello-cli
description: Operate Trello through the local `trello` CLI. Use when reading or changing Trello boards, lists, cards, comments, checklists, attachments, labels, members, or custom fields, and when exercising the binary from the Trello_CLI repository.
---

This skill teaches you how to translate natural-language Trello requests into safe, multi-step `trello` CLI workflows. The CLI outputs deterministic JSON — every response is machine-parseable and follows a stable contract.

## Dependency

Requires the `trello` CLI from [Scale-Flow/trello-cli](https://github.com/Scale-Flow/trello-cli). Install it on `PATH`, or clone the repo and build with `go build -o bin/trello ./cmd/trello`.

## Resolve the Binary

Try these in order — use whichever works first:

1. `trello` on `PATH`
2. `./bin/trello` (relative to the repo root)
3. Build from the repo: `go build -o bin/trello ./cmd/trello`

Once resolved, use that path for all subsequent commands in the session.

## Preflight: Check Auth

Before any resource command, verify credentials are configured:

```bash
trello auth status
```

The response follows the JSON envelope. Stop and explain the issue to the user if any of these hold — do not attempt resource commands:

- `ok` is `false`
- `data.configured` is `false` (no credentials stored — a fresh install)
- `data.authMode` is `"key_only"` (API key without a token; not enough to authenticate)

Auth can come from three sources:
- **Device flow** (preferred — via `trello auth login` with Power-Up pairing)
- **OS keyring** (stored credentials via `trello auth set` or `trello auth login`)
- **Environment variables** `TRELLO_API_KEY` and `TRELLO_TOKEN`

## Current Trello User

For shareable workflows that need to assign "me" or the current agent operator, never hardcode a member name. Treat the authenticated Trello account as runtime state:

1. Run `trello auth status`.
2. Read the member ID from the returned `data` payload when present, such as `data.member.id` or `data.idMember`.
3. If auth status does not expose a member ID, list board members with `trello members list --board <board-id>` and match the authenticated username/full name from auth status.
4. Use that discovered member ID for `trello members add --card <card-id> --member <member-id>`, then re-fetch the card to verify the member is assigned.

If the current user cannot be resolved unambiguously, report the blocker instead of assigning a guessed teammate.

### Device Flow Authentication (Preferred)

When authenticating a new user, prefer the device flow over manual API key setup:

1. Run `trello auth login` — this contacts the pairing service and displays a code
2. Present the pairing code to the user: "Enter this code in your Trello board's CLI Connector Power-Up: XXXX-XXXX"
3. The command blocks until the user completes pairing (up to 15 minutes)
4. On success, credentials are stored automatically — no API key or token handling needed
5. If the pairing service is unavailable, the CLI falls back to browser-based login automatically

The device flow is ideal for non-technical users and agent-driven workflows because it requires no developer portal access.

## Core Workflow: Discover, Mutate, Verify

Every Trello task follows this shape:

1. **Discover** — find the IDs you need (boards, lists, cards) using read commands or search
2. **Mutate** — run the minimum command to accomplish the task
3. **Verify** — re-fetch the resource to confirm the change took effect

This matters because the CLI uses IDs, not names. Never guess an ID — always discover it first.

For any workflow that writes to Trello, read `references/discover-mutate-verify.md` before the first mutation and use its completion criteria. A Trello write is not complete until a follow-up read proves the remote state changed.

**Example:** "Create a card in the Doing list on the Marketing board"
1. `trello boards list` → find Marketing board ID
2. `trello lists list --board <board-id>` → find Doing list ID
3. `trello cards create --list <list-id> --name "My card"`
4. `trello cards get --card <card-id>` → confirm creation

## JSON Contract

Every command returns one of two envelopes:

```json
{"ok": true, "data": ...}
{"ok": false, "error": {"code": "...", "message": "..."}}
```

Always branch on `ok`. Read payloads from `data`, errors from `error.code` and `error.message`. The `--pretty` flag changes formatting only, not the schema.

Use compact JSON (no `--pretty`) when piping output or extracting values programmatically. Use `--pretty` when showing results to the user.

## Safety Rules

- **Prefer reads first** when names are ambiguous — list boards/lists before mutating
- **Use IDs after discovery** — never pass names where an ID is expected
- **Never guess IDs** — always discover them from a list or search command
- **Re-fetch after mutations** when confirmation matters
- **Validate file paths** before `attachments add-file`
- **Download attachments to files** with `attachments download`; never expect binary content on stdout
- **Use ISO-8601** for `--due` and `--date` values
- **`cards list` requires exactly one** of `--board` or `--list`, never both
- **Update commands need at least one** mutation field

## Getting Images Out of Trello Cards

When the user asks for screenshots, mockups, images, photos, design references, or other visual assets from a Trello card, treat those as card attachments.

Use this workflow:

1. Discover the card ID with `search cards`, `cards list`, or `cards get`
2. `trello attachments list --card <card-id>` — inspect `mimeType`, `name`, `fileName`, and `isUpload`
3. Pick image attachments by `mimeType` starting with `image/`, or by image file extensions in `fileName`, `name`, or `url`
4. Download each image with `trello attachments download --card <card-id> --attachment <attachment-id> --output <local-file-or-existing-dir>`
5. Read or inspect the saved file from the returned `data.path`

Do not fetch Trello attachment URLs directly with `curl` or browser automation unless the CLI download command is unavailable. Trello-hosted uploaded files often need OAuth authorization; `attachments download` handles this and keeps stdout JSON-only.

Use an existing directory as `--output` when preserving Trello filenames is acceptable. Use an explicit file path when the user needs a stable name. The command refuses to overwrite files unless `--force` is passed, so only use `--force` when replacing the file is intended.

## Intent Interpretation

When the user describes a Trello task in natural language, translate it into a multi-step workflow — not a single command. Think about what IDs you need and how to get them.

Common patterns:
- "Move card X to Done" → discover the Done list ID, then `cards move`, then verify
- "Add a checklist to card X" → `checklists create`, add items, list to confirm
- "Find boards about marketing" → `search boards --query marketing` or `boards list` and filter
- "Set priority to High on card X" → discover custom field ID, then `custom-fields items set`
- "Get the images from card X" → discover the card ID, `attachments list`, filter image attachments, then `attachments download` to a local directory

Read `references/task-recipes.md` for complete workflow recipes covering all resource types.
Read `references/attachment-download.md` when card attachments are source material that must be downloaded and inspected before implementation or QA.

## Command Reference

The CLI has 12 top-level command groups: `auth`, `boards`, `lists`, `cards`, `comments`, `checklists`, `attachments`, `custom-fields`, `labels`, `members`, `search`, `version`.

Read `references/command-digest.md` for the full command surface, flags, and validation rules.

## Error Handling

When a command returns `ok: false`, check the error code:

| Code | Meaning | What to do |
|------|---------|------------|
| `AUTH_REQUIRED` | No credentials configured | Guide user through `auth set` or `auth login` |
| `AUTH_INVALID` | Credentials rejected by Trello | Credentials may be expired — re-authenticate |
| `NOT_FOUND` | Resource ID doesn't exist | Re-discover the ID |
| `VALIDATION_ERROR` | Bad input (missing flag, wrong format) | Fix the command flags |
| `RATE_LIMITED` | Trello API rate limit hit | Wait and retry |
| `CONFLICT` | Resource state conflict | Re-fetch and retry |
