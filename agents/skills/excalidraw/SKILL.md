---
name: excalidraw
description: Generate and edit Excalidraw diagram files (.excalidraw JSON) — architecture diagrams, flowcharts, workflows, ERDs. Use when asked to create, modify, or fix an Excalidraw diagram. Not for Mermaid or FigJam.
---

# Excalidraw diagrams

Write `.excalidraw` JSON by hand, validate it with the bundled script, and only then hand it over. The full file format lives in [`references/format.md`](references/format.md) — read it before writing your first element; it covers required properties, binding rules, and load-time gotchas that silently break files.

## Workflow

1. **Project context.** Diagrams should use the project's design language, not an invented one:
   - If the user names a project, use that project's colors/typography — check its repo for `DESIGN.md`, design tokens, Tailwind config, or CSS variables.
   - Else, if `DESIGN.md` exists in the current repo (root or `docs/`), use it.
   - Otherwise use Excalidraw's native palette (in `format.md`) — files built from it look hand-made in the app. Do not invent a brand palette.
   - Whatever the source: pair a darker stroke with a lighter fill, assign colors by meaning (state, layer, ownership), and keep the mapping consistent across the diagram.
2. **Plan before JSON.** Pick a visual pattern per concept (table below), sketch coordinates on paper first: flow direction (left→right or top→bottom for sequences, radial for hub-and-spoke), sizes, gaps. Diagrams should argue, not display — if you removed all the text, the structure alone should still communicate the idea.
3. **Write the JSON** following `format.md` and the layout rules below. For editing an existing file, see "Editing" first.
4. **Validate:** `uv run <skill-dir>/scripts/validate.py diagram.excalidraw` (stdlib-only; plain `python3` works too). Fix every ERROR; treat WARNs as a to-do list unless intentional (e.g. deliberate overlap in a cloud motif). Re-run until clean.
5. **Visual check (when possible):** `uv run <skill-dir>/scripts/render.py diagram.excalidraw` renders a PNG via Excalidraw's real exporter (needs network + `uv run --with playwright playwright install chromium` once). View the PNG and fix what looks wrong: crossing arrows, cramped vs. empty regions, illegible text, lopsided composition. Iterate. If rendering isn't available, the validator plus careful coordinate math is the fallback.

## Choosing structure

| The concept... | Pattern |
|---|---|
| Spawns multiple outputs | Fan-out (radial arrows from center) |
| Combines inputs into one | Convergence (arrows merging) |
| Has hierarchy/nesting | Tree |
| Is a sequence of steps | Timeline / pipeline |
| Loops or iterates | Cycle (arrow returning to start) |
| Transforms input to output | Before → process → after |
| Compares two things | Side-by-side |
| Separates into phases | Visual gap between sections |

## Layout rules

- **Container discipline.** Default to free-floating text; box things only when the box carries meaning (a component, a boundary, a state). Aim for well under half of text elements inside containers. For each boxed element ask: would this work as plain text? If yes, unbox it.
- **Connections are explicit.** Position alone doesn't show relationships — if A relates to B, draw a bound arrow.
- **Hierarchy through size and stroke, never opacity.** Everything at `opacity: 100`; bigger + bolder = more important. Give the most important element the most whitespace.
- **Consistent scale ladder.** Pick 2–3 box sizes (e.g. 200×100 primary, 140×70 secondary) and 2–3 font sizes (e.g. 28 title, 20 label, 16 annotation) and stick to them. Snap coordinates to the 20px grid.
- **Spacing.** Keep ≥40px between sibling boxes, more between sections. Uneven whitespace reads as broken.

## Construction rules

The mechanical rules the validator enforces; the reasons are in `format.md`:

- Write every styling property explicitly (defaults have drifted between Excalidraw versions).
- Descriptive ids (`"api-box"`, `"api-to-db"`), a distinct random integer `seed` per element, no `index` field. Z-order = array order.
- Bindings are bidirectional — text↔container and arrow↔shape each need both sides written.
- Arrow bindings use `{elementId, focus, gap}`, never `fixedPoint`/`mode`.
- Center bound text in its container yourself; size text `width`/`height` with the formulas in `format.md`.
- Arrow/line `points` are relative to the element's `x`/`y` and start at `[0, 0]`.

## Editing existing files

- Read the whole file first. Preserve properties you don't recognize — Excalidraw keeps unknown fields for forward compatibility, so must you.
- Keep existing `id`s stable; bump `version` and `updated` on elements you change.
- When deleting an element, remove every reference to it: entries in other elements' `boundElements`, arrows' `startBinding`/`endBinding`, texts' `containerId`, children's `frameId`. The validator catches stragglers.
- When moving a shape, move its bound text with it and re-derive the endpoints of bound arrows.
- Large diagrams: build section by section, validating between sections; cross-section arrows are added last, updating `boundElements` on the earlier elements.
