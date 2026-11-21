---
name: dogfood
description: Systematically explore a web app to find reproducible bugs and usability problems. Use for dogfooding, exploratory QA, bug hunts, and testing an app's quality. Produce a structured report with screenshots, reproduction steps, and video for interaction bugs. Prefer the available built-in browser; use Agent Browser when CLI automation or recording is needed.
allowed-tools: Bash(agent-browser:*)
---

# Dogfood

Explore the requested app as a user and document reproducible findings as you go. Use the target URL and scope from the request. Default to `./dogfood-output/` for reports and evidence. Follow any invoking skill's acceptance criteria and viewport requirements.

## Choose tools and load the workflow

Follow the local `agent-browser` skill's browser selection rules. Prefer the current product's built-in browser for interactive exploration. Use Agent Browser when reproducible CLI automation, recording, or diagnostics require it.

When Agent Browser is installed, read its version-matched dogfood workflow:

```bash
agent-browser skills get dogfood
agent-browser skills get dogfood --ref issue-taxonomy
```

When driving the CLI, also read `agent-browser skills get core` before the first browser command. Generate a session name with `agent-browser session id --scope worktree --prefix dogfood` and pass `--session <name>` on every browser command. A domain alone is not an isolated session name.

The upstream instruction to always use Agent Browser does not override the user's browser preference. Adapt its navigation, snapshots, screenshots, and evidence collection to the selected browser. Keep required desktop/mobile coverage, console/network checks, and accessibility evidence. Use the CLI for capabilities the selected browser lacks and report any remaining gaps.

Relative paths in the upstream workflow refer to `agent-browser skills path dogfood`. Retrieve the report template without copying from this local skill directory:

```bash
mkdir -p dogfood-output/screenshots dogfood-output/videos
agent-browser skills get dogfood --ref templates/dogfood-report-template.md > dogfood-output/report.md
```

Substitute the requested output directory. Create the report once; resume an existing report without overwriting findings. Load other references with `agent-browser skills get dogfood --ref <name>` as needed.

## Explore and report

These rules also provide the workflow when the CLI is unavailable. Use the local [issue taxonomy](references/issue-taxonomy.md) and [report template](templates/dogfood-report-template.md) in that case.

1. Initialize the report with the target, scope, date, and browser/session. Authenticate through the available login flow when needed. Keep credentials and saved auth state out of reports and committed evidence.
2. Orient from the app's navigation, then exercise core workflows, forms, empty/error states, boundary inputs, and adjacent flows. Inspect console errors, failed requests, and accessibility on the pages tested.
3. Verify each suspected issue with a retry. Document it immediately with expected/actual behavior, severity, URL, viewport, and numbered reproduction steps.
4. For interaction bugs, capture a watchable reproduction video and screenshots of the steps and result. For static issues, capture one annotated screenshot. If recording is unavailable, include the screenshots and steps and state that video is unavailable.
5. Update severity counts to match the findings, preserve the evidence, and close only the session you created. Summarize findings, tested coverage, and anything unverified. Attach final evidence to the PR when the task includes one.

Do not target an issue count. Report only observed, reproducible findings; zero findings is valid. Test through the browser rather than reading the target app's source. For ticket QA, apply the invoking skill's rules for reading the PR and acceptance criteria.
