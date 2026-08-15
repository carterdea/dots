---
name: html-communication
description: When the user asks for an HTML writeup of work (NOT as part of the codebase), use this skill to create it and report its local path, or a hosted link when one is needed.
---

# HTML Communication

## When to Use

Use this skill when the user wants a plan, spec, write-up, findings, summary, report, comparison, or set of UI mocks presented as readable HTML.

Do not use it for HTML that ships as part of a product.

## Document

Create one self-contained HTML file, capped at 512 KB.

- Write it like a spec, not a landing page: dense, scannable, no hero, decorative chrome, marketing voice, or em dashes.
- Do not impose a palette. Default to a plain light document — white background, black text — and match the client's brand, type, and color when the work has one.
- Make it mobile-readable with a responsive viewport and no fixed-width layout.
- Use semantic HTML, inline CSS, inline SVG, and HTTPS or data-URL images.
- Use an inline classic script only when interactivity materially helps. Keep scripted pages useful without JavaScript.
- In script-free files, give external links `target="_blank"` and `rel="noopener noreferrer"`. If any script exists, omit `target="_blank"`.

Never include external or module scripts, inline event handlers, `javascript:` URLs, forms, frames, embeds, objects, applets, meta refresh, linked stylesheets, secrets, private URLs, or local filesystem paths.

## UI Mocks

When the user asks for variants:

- Render real styled variants, not descriptions.
- Label them `A`, `B`, `C`... for easy selection.
- Lay them out for direct comparison.
- Keep one file across iterations so its link stays stable.

Report the link and stop. Wait for a pick before touching real components.

## Publish

Write the file locally and report its path. That is the whole job when Carter is at the machine, which is most of the time.

Publish a hosted copy when a local path is useless — Carter says he is on mobile or away, he asks for a shareable link, or the session itself is remote (cloud agent, SSH, sandbox with no local browser). Use whatever publishing the harness offers; in Claude Code that is the Artifact tool, which returns a private URL on Carter's account. If the harness offers none, report the local path and say a link is not available here.

Never claim the document is hosted before publishing succeeds. Do not verify in a browser unless Carter asks.
