---
name: agent-browser
description: Browser automation with the agent-browser CLI. Use for reproducible CLI automation, recordings, targeted diagnostics, or browser capabilities unavailable in the current product's built-in browser. Covers navigation, forms, screenshots, extraction, QA, accessibility, Electron apps, API discovery, and protected Vercel previews. Prefer an available built-in browser for ordinary interactive browsing and preview QA.
allowed-tools: Bash(agent-browser:*)
hidden: true
---

# Agent Browser

## Choose the browser

Prefer the current product's available built-in browser for interactive browsing and preview QA. In ChatGPT/Codex desktop use `@Browser`; in Claude Cowork use its built-in browser. Claude Code/CLI sessions may expose Claude in Chrome. Honor an explicitly requested browser and use only tools available in the session.

Use Agent Browser for reproducible CLI automation, recording, targeted diagnostics, or when the built-in browser cannot meet the task. Keep required viewport coverage, screenshots, console/network checks, accessibility evidence, and project Playwright/e2e checks. Report missing capabilities instead of silently skipping checks.

## Load instructions from the installed CLI

Before the first browser command, run and read:

```bash
agent-browser --version
agent-browser skills get core
```

The CLI bundles instructions matching its version. Load these at runtime instead of using copied command manuals. Use the installed `agent-browser` binary directly. If it is unavailable or lacks `skills get`, use an available supported browser and report the limitation. Check the current release and installation method before proposing an upgrade. On Homebrew installations, use `brew upgrade agent-browser`; use pnpm or Bun for package-manager installations.

Load only the reference needed for the task:

```bash
agent-browser skills get core --ref commands
agent-browser skills get core --ref authentication
agent-browser skills get core --ref video-recording
```

Use `--full` only when all references are needed. To access bundled files, use `agent-browser skills path core`; relative paths in CLI-served instructions refer to that directory, not this local skill.

## Load specialized workflows

Discover the installed catalog with `agent-browser skills list`, then run `agent-browser skills get <name>` for the matching task. The catalog currently includes:

| Skill | Task |
| --- | --- |
| `dogfood` | Exploratory QA with reproduction evidence. Read the local `dogfood` skill for browser selection and reporting rules. |
| `derive-client` | Record network traffic and derive a site's API client. |
| `electron` | Operate Electron apps through their debugging connection. |
| `slack` | Browser-based Slack tasks when connected Slack tools cannot do the work. |
| `protected-vercel-deployments` | Open protected Vercel previews. |
| `vercel-sandbox` | Run Chrome inside a Vercel Sandbox. |
| `agentcore` | Use AWS Bedrock AgentCore cloud browsers. |
| `webmcp-gen` | Build and validate WebMCP tools for a page. |
| `modern-web-guidance` | Apply Chrome's guidance and verify the result in a browser. |

Use the names returned by the installed CLI. For Modern Web Guidance, use pnpm or Bun equivalents of upstream `npx` examples and verify the package version with Context7 or Exa before running it.

## Local operating rules

- Get a session name with `agent-browser session id --scope worktree --prefix <task>` and pass `--session <name>` on every browser command. Shell exports may not survive between tool calls. Never use the shared default session.
- Use snapshots to inspect page state. Keep screenshots and recordings required for visual QA or reproduction evidence, even when the core guide discourages routine screenshots.
- Prefer sufficient connected service tools over browser automation. A skill describing an action does not authorize messages, purchases, deployments, or other external changes.
- Close only the named session you created when finished.

[Official skills documentation](https://agent-browser.dev/skills)
