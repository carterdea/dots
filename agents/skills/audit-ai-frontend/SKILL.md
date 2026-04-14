---
name: audit-ai-frontend
description: Audit AI-generated or AI-looking frontend implementations, UI screenshots, and design diffs for generic AI aesthetics, card/gradient/font tells, weak UX copy, accessibility gaps, brittle responsive behavior, and one-off design-system drift. Use when reviewing or restyling React, Tailwind, shadcn/ui, HTML/CSS, landing pages, dashboards, or app screens to make the UI feel more intentional without a full redesign unless explicitly requested.
---

# AI Frontend Audit

## Use

Audit or repair frontend UI that looks generically AI-generated, while preserving existing structure unless the user asks for a redesign.

Review in this order:

1. Inspect code and UI together.
   - Read components, CSS/theme tokens, and existing primitives first.
   - If runnable, drive the page with your browser automation tool (`agent-browser` CLI preferred; otherwise Playwright, Playwright MCP, or any equivalent). This skill decides what to inspect, not browser mechanics.
   - If screenshot-only, review visuals but label implementation risks as `Inferred`.

2. Load only the reference you need.
   - `references/patterns.md` for concrete AI-tell and code-smell fixes.
   - `references/rubric.md` for broad UX/a11y/design audits.
   - `references/workflows.md` for browser QA, reference-packet, and brief-lock loops.

3. Preserve local system intent while removing accidental defaults.
   - Keep copy/order/IA and known product tokens unless the user asks for a redesign.
   - Keep a common-looking font/card/palette only if adjacent screens or documented tokens already use it; replace it when the style exists only in the generated screen.
   - If references are missing, derive one explicit design contract from product domain + user job + existing primitives; do not fabricate named reference sites.

4. Fix in this order.
   - `P0`: keyboard, labels, contrast, touch targets, mobile overflow, missing loading/empty/error states.
   - `P1`: generic SaaS layout, card overuse, icon-pill repetition, Inter/Roboto/system defaults, purple/indigo/cyan gradient/glass tropes, vague CTA/copy.
   - `P2`: spacing rhythm, token consistency, one memorable visual rule, reduced-motion and state polish.

5. Re-verify in browser after edits whenever possible.

## Output

For each finding, include:

- `Issue`
- `Evidence`
- `Class` (`P0`, `P1`, `P2`)
- `Why it matters / why it reads as generic`
- `Possible non-AI explanation`
- `Smallest fix`
- `Acceptance check`
- `Confidence` (`High`, `Medium`, `Low`)
- `File/line` when code is available

Return only the top 5-8 findings and merge repeated symptoms under one root cause. End with one line: `If I had to change only one thing: ...`

For implementation asks, patch the code directly, then summarize only the meaningful design changes and any remaining risk.

## Guardrails

- Treat "AI-looking" as a quality smell, not a provenance claim.
- Prefer objective defects over taste opinions.
- When auditing shadcn/ui projects, preserve semantic component usage and tokens. Reach for shadcn-specific tooling (registry install/update, composition rules) when component APIs are part of the fix.
- Avoid anti-slop overcorrection: no random ornaments, novelty fonts, or one-off visual chaos.
- Anchor each finding in code, screenshots, DOM/a11y snapshots, or browser behavior, and separate fact from inference.

## Resource

- `references/patterns.md`: checklist of AI-frontend tells, code smells, and repair patterns.
- `references/rubric.md`: compact UX/a11y/design-quality rubric for broader audits.
- `references/workflows.md`: Browser QA, reference-packet, and brief-lock loops; delegates browser mechanics to your automation tool of choice (`agent-browser` CLI preferred).
