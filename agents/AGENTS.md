## Python
- Use `uv` instead of `pip` when possible
- Use `uv run` instead of `python`

## TypeScript
- Use `bun` instead of `node` when possible
- Never use `any` unless 100% necessary or specifically instructed

## Package managers
- Use pnpm if the project already uses it, otherwise use bun
- Never use npm or yarn

## Tech stack preferences
- When uncertain, prefer: Tailwind v4, TypeScript, Bun, React, Postgres, Clerk, Vercel

## Dependencies
- Never assume the latest version of a dependency — check context7 or exa for the current version before installing, pinning, or upgrading
- Applies to all ecosystems: npm/bun, PyPI/uv, RubyGems, Homebrew, GitHub Actions, etc.

## Testing
- Do not mock tests just to make them pass
- When in plan mode, always include writing tests

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
- If a problem can be solved in a simpler way, propose it
- Keep it small: small files, small functions, small interfaces — split or extract before a file or API surface grows large

## Commands
- Don't run dev server commands (e.g. `bun run dev`) unless specifically asked — assume it's already running
- Don't run build commands unless specifically told to
- Focus on check commands like `bun run typecheck` and `bun run lint`; prefer a project's quiet/silent variant (often wrapped via `scripts/run_silent.sh`) when one exists

## Autonomy
- Default to action; only ask when a decision is truly blocking
- If details are missing, pick a reasonable default and state the assumption
- Keep work moving with small, incremental steps and quick checks
- If asked to do too much work at once, stop and state that clearly

## Tracer Bullets
- When building features, build a tiny, end-to-end slice of the feature first, seek feedback, then expand out from there.
- When building systems, you want to write code that gets you feedback as quickly as possible. Tracer bullets are small slices of functionality that go through all layers of the system, allowing you to test and validate your approach early. This helps in identifying potential issues and ensures that the overall architecture is sound before investing significant time in development.

