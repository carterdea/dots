## Who we are

I'm Carter De Angelis. We work together — you and me — on a lot of apps: mostly Node.js, plus Python and Ruby, and plenty of Shopify.

The work is making complex things simple. Reduce complexity while solving the problem, not in a cleanup pass afterward.

## Questions are read-only
- A question is a request for an answer, not for changes. If the message opens with "how hard would it be", "what are your thoughts", "why does", "should we", "is it possible", "can X do Y", or otherwise asks rather than instructs: answer it, and do not edit files
- If the answer is obvious and the change is trivial, still answer first and offer the change. Ask before making it

## Python
- Use `uv` instead of `pip` when possible
- Use `uv run` instead of `python`

## TypeScript
- Use `bun` instead of `node` when possible
- `any` is the enemy — never use it unless 100% necessary or specifically instructed
- Inferred types are our friend. Our systems should adapt to changes instead of requiring changes everywhere
- If your TS code looks like a Python dev wrote it, it is bad TS code
- Avoid one-line functions that are just casting wrappers
- Write TypeScript in ways that Matt Pocock and Theo would be proud of

## Package managers
- Default to pnpm; otherwise use whatever the project already uses
- Never use npm or yarn

## Tech stack preferences
- When not already specified in the project, prefer: Postgres, Tailwind v4, TypeScript, React, Vite, pnpm, deployed on Vercel
- For more complex web and React Native apps, pull in: Zustand, React Query, Tanstack Start, Clerk (or better-auth when self-hosting), and zod

## Dependencies
- Never assume the latest version of a dependency — check context7 or exa for the current version before installing, pinning, or upgrading
- Applies to all ecosystems: npm/bun, PyPI/uv, RubyGems, Homebrew, GitHub Actions, etc.

## Testing
- Tests are good; endless smoke tests and "regression tests" for feature deletions are much less good. Tests should be focused, not slop
- Do not mock tests just to make them pass
- When in plan mode, always include writing tests
- Treat lint failures, test failures, and test flakiness as engineering quality problems worth fixing, even when they are not caused by the current change

## Planning and task management
- When creating planning documents, use markdown checkboxes for tasks
- When completing tasks from a planning document, check them off

## Git workflow
- Never use `git add .`; select files one at a time
- Commit often in logical groups
- Do not work on `main` unless given permission

## Writing and content
- Do not use emojis in pull requests
- Do not make up fake case studies or numbers
- Sacrifice grammar for the sake of concision
- List any unresolved questions at the end, if any

## Code style
- Always strive for concise, simple solutions
- Keep things simple; channel "yagni" energy unless told otherwise
- Typesafety is useful — take advantage of it
- When making technical decisions, weigh quality, simplicity, robustness, scalability, and long-term maintainability above development cost in time or effort
- If a problem can be solved in a simpler way, propose it
- Keep it small: small files, small functions, small interfaces — split or extract before a file or API surface grows large

## Comments
- Comments are a great way to clarify functionality and how code is used
- Don't comment every line, but feel free to describe concisely how functions are used above function definitions, classes, etc.
- Keep comments up to date — when making changes, keep things in sync

## UI quality
- When end-to-end testing a website or app, be picky about the UI and aim for pixel polish
- If something clearly looks off, try to fix it along the way even when it is not directly related to the current task

## Visual and design work
- Do not edit real components first. For any non-trivial UI, layout, or copy change, build several distinct static mocks, publish them with the `html-communication` skill, report the URL, and stop. Wait for a pick before implementing
- Standing constraints: information-dense, no decorative card/pill chrome, no light-gray subtitle lines above sections. Minimal copy. No em dashes
- Do not impose a palette. Default to a plain light document and match the client's brand, type, and color when the work has one
- Avoid continuously repainting CSS animations (pulse, shimmer, blur, spinners); they peg the GPU on high-refresh displays

## Blast radius
- Never touch production, live databases, or daily-driver build/preview channels unless explicitly told to

## General preferences
- If computer use is helpful for completing or verifying work, shell out to gpt-5.6-sol with Codex for it

## Commands
- Don't run dev server commands (e.g. `bun run dev`) unless specifically asked — assume it's already running
- Don't run build commands unless specifically told to
- Focus on check commands like `bun run typecheck` and `bun run lint`; prefer a project's quiet/silent variant (often wrapped via `scripts/run_silent.sh`) when one exists

## Autonomy
- Default to action; only ask when a decision is truly blocking
- Don't be scared to propose bold ideas if they can meaningfully benefit our work
- Be careful with destructive actions that are not explicitly requested
- If details are missing, pick a reasonable default and state the assumption
- Keep work moving with small, incremental steps and quick checks
- If asked to do too much work at once, stop and state that clearly

## Match ceremony to the task
- Do not spawn subagents or a multi-agent panel for work a single agent finishes in one pass. Delegation is for breadth or adversarial review, not for ordinary tasks
- When several agents do work in parallel, state file ownership up front so they do not collide

## Tracer Bullets
- When building features, build a tiny, end-to-end slice of the feature first, seek feedback, then expand out from there.
- When building systems, you want to write code that gets you feedback as quickly as possible. Tracer bullets are small slices of functionality that go through all layers of the system, allowing you to test and validate your approach early. This helps in identifying potential issues and ensures that the overall architecture is sound before investing significant time in development.
