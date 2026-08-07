# .excalidraw file format reference

Targets the **released** Excalidraw format (`@excalidraw/excalidraw` 0.18.x, what excalidraw.com runs). Master has drifted in a few places; every drift is called out below. Files written to this spec load on both.

## Top-level structure

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [],
  "appState": { "gridSize": 20, "viewBackgroundColor": "#ffffff" },
  "files": {}
}
```

Load-time validation is minimal: `type` must be `"excalidraw"`; `elements` (if present) must be an array; `appState` (if present) an object. Always emit all six keys anyway.

`files` holds image data, keyed by file id (key must equal inner `id` must equal the image element's `fileId`):

```json
"files": {
  "<fileId>": {
    "mimeType": "image/png",
    "id": "<fileId>",
    "dataURL": "data:image/png;base64,...",
    "created": 1690295874454,
    "lastRetrieved": 1690295874454
  }
}
```

## Common element properties

Every element carries all of these. Third column = what Excalidraw substitutes when the key is missing.

| Property | Type | Default on load |
|---|---|---|
| `id` | string | random |
| `type` | string | **required** — unknown types are silently dropped |
| `x`, `y` | number | 0 |
| `width`, `height` | number | 0 (negatives normalized by flipping) |
| `angle` | number, radians, about center | 0 |
| `strokeColor` | CSS color | `"#1e1e1e"` (falsy `""` also replaced) |
| `backgroundColor` | CSS color | `"transparent"` |
| `fillStyle` | `"solid" \| "hachure" \| "cross-hatch" \| "zigzag"` | drifted between versions — always write it |
| `strokeWidth` | number — UI uses 1 / 2 / 4 | 2 (falsy `0` also replaced) |
| `strokeStyle` | `"solid" \| "dashed" \| "dotted"` | `"solid"` |
| `roughness` | 0 clean / 1 artist / 2 sketchy | 1 |
| `opacity` | number 0–100 | 100 |
| `roundness` | `null` or `{"type": 1\|2\|3}` | `null` |
| `seed` | integer (drives hand-drawn jitter) | 1 — use a distinct random int per element |
| `version` | integer ≥ 1 | 1 |
| `versionNonce` | integer | 0 (fine to write 0) |
| `index` | fractional index string | **omit or `null`** — reassigned from array order on load |
| `isDeleted` | boolean | false |
| `groupIds` | string[], deepest group first | `[]` |
| `frameId` | string \| null | null |
| `boundElements` | `[{"id", "type": "arrow"\|"text"}]` \| null | `[]` |
| `updated` | epoch ms | now |
| `link` | string \| null | null |
| `locked` | boolean | false |

Z-order is array order (earlier = behind). Unknown extra properties are preserved on load — never strip fields you don't recognize when editing an existing file.

Roundness: rectangles (and image/embeddable) use `{"type": 3}` (fixed 32px radius); arrows, lines, diamonds use `{"type": 2}` (proportional). `null` = sharp corners.

## Element types

**rectangle / ellipse / diamond** — base properties only.

**text**

```json
{
  "type": "text", "text": "Label", "originalText": "Label",
  "fontSize": 20, "fontFamily": 5, "lineHeight": 1.25,
  "textAlign": "center", "verticalAlign": "middle",
  "containerId": null, "autoResize": true
}
```

- `fontFamily` codes (release): `1` Virgil, `2` Helvetica, `3` Cascadia (mono), `5` Excalifont (default), `6` Nunito, `7` Lilita One, `8` Comic Shanns, `9` Liberation Sans. `4` and `10` are not valid in the release.
- `lineHeight` is unitless and font-specific: 1.25 (Excalifont, Virgil, Nunito, Comic Shanns), 1.15 (Lilita One, Helvetica, Liberation Sans), 1.2 (Cascadia).
- `text` = rendered string with wrap-inserted `\n`; `originalText` = unwrapped. Setting both to the same value is always safe.
- `textAlign`: left/center/right; `verticalAlign`: top/middle/bottom.
- Do not write the legacy `baseline` field.
- **Height is exact**: `fontSize * lineHeight * lineCount`. **Width must be estimated** and is NOT repaired on file load — a wrong width renders misaligned until a user edits the text. Estimate `0.5 × fontSize` per char (0.6 for Cascadia), use the longest line. Prefer `textAlign: "left"` for free-floating text so estimation error shifts nothing.
- Empty text (`""`) is deleted on load.

**arrow**

```json
{
  "type": "arrow", "points": [[0, 0], [150, 0]],
  "startBinding": {"elementId": "box-a", "focus": 0, "gap": 1},
  "endBinding": {"elementId": "box-b", "focus": 0, "gap": 1},
  "startArrowhead": null, "endArrowhead": "arrow",
  "elbowed": false, "lastCommittedPoint": null
}
```

- Binding format is `{elementId, focus, gap}` — `focus` −1..1 (0 = centered), `gap` > 0 px. Master's newer `{elementId, fixedPoint, mode}` format is auto-migrated FROM this, but the release does not understand it — **never write `fixedPoint`/`mode`**.
- `endArrowhead` absent defaults to `"arrow"`; explicit `null` = none. Safe values on all versions: `arrow`, `bar`, `circle`, `circle_outline`, `triangle`, `triangle_outline`, `diamond`, `diamond_outline`; plus `crowfoot_one`, `crowfoot_many`, `crowfoot_one_or_many` for ERDs. Invalid strings render as nothing, with no error.
- `elbowed: true` = orthogonal routing.

**line** — same shape as arrow but bindings are always nulled on load (lines cannot bind). Arrowheads allowed.

**Points** (arrow/line/freedraw) are `[x, y]` pairs **relative to the element's `x`/`y`**. Rules enforced on load: at least 2 points (else replaced with `[[0,0],[width,height]]`); `points[0]` must be `[0,0]` (else rebased); `width`/`height` recomputed from point extent.

**freedraw** — `points`, `pressures: []`, `simulatePressure: true`.

**image** — `fileId` (must exist in `files`), `status: "saved"`, `scale: [1, 1]`, `crop: null`.

**frame** — `name: string | null`; children reference it via their `frameId`.

**embeddable** — URL goes in the standard `link` property.

Never write `type: "selection"` (filtered out on load).

## Text-in-container binding

Bidirectional — write both sides:

- Container: `"boundElements": [{"id": "<text-id>", "type": "text"}]`
- Text: `"containerId": "<container-id>"`, `textAlign: "center"`, `verticalAlign: "middle"`

Valid containers: rectangle, diamond, ellipse, arrow. Half-specified bindings are healed on load; dangling ids are dropped/nulled.

**Bound text `x`/`y` are NOT recomputed for shape containers** — center it yourself:
`text.x = container.x + (container.width - text.width) / 2`, same for y with heights.

Available text area (padding 5px each side): rectangle `w − 10`; ellipse `round(w/2 × √2) − 10`; diamond `round(w/2) − 10`; arrow label `max(0.7w, fontSize × 11)`. Same formulas for height. To size a container around text of dimension `d`: rectangle `d + 10`, ellipse `round((d + 10)/√2 × 2)`, diamond `2 × (d + 10)`.

## Arrow-to-shape binding

Also bidirectional: arrow carries `startBinding`/`endBinding`, and **each target's `boundElements` must include `{"id": "<arrow-id>", "type": "arrow"}`**. Place the arrow's endpoints just outside the target's border (that's what `gap` represents). Bindings whose `elementId` isn't in the scene are nulled on load.

## Excalidraw+ REST API (pushing to a hosted workspace)

`https://api.excalidraw.com/api/v1`, `Authorization: Bearer <key>` (public beta). Scene content (`PUT /scenes/{id}/content`) validates against the **master** schema, stricter than the app's file loader:

- Full document wrapper required (`type`, `version`, `source`, `elements`, …)
- Every element needs a fractional `index` string (files should omit it; the API rejects its absence)
- Arrow bindings need `fixedPoint: [fx, fy]` (normalized 0–1 on the target) and `mode: "inside"|"orbit"|"skip"` — keeping `focus`/`gap` alongside is accepted
- Creating a scene (`POST /collections/{id}/scenes`) requires `pinned`

Don't hand-write these into `.excalidraw` files — `scripts/push.py` adds them on the way out, keeping files app-compatible.

## Default palette

Excalidraw's native colors — generated files using these look hand-made in the app:

- Strokes: `#1e1e1e` black, `#e03131` red, `#2f9e44` green, `#1971c2` blue, `#f08c00` orange
- Backgrounds: `transparent`, `#ffc9c9` red, `#b2f2bb` green, `#a5d8ff` blue, `#ffec99` yellow

## Worked example

Two labeled boxes joined by a bound arrow — every binding reciprocal, no `index` fields:

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [
    {
      "id": "box-a", "type": "rectangle",
      "x": 100, "y": 100, "width": 180, "height": 80,
      "angle": 0, "strokeColor": "#1e1e1e", "backgroundColor": "#a5d8ff",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 1, "opacity": 100, "seed": 1234567,
      "version": 1, "versionNonce": 0, "isDeleted": false,
      "groupIds": [], "frameId": null, "roundness": {"type": 3},
      "boundElements": [{"id": "label-a", "type": "text"}, {"id": "arrow-1", "type": "arrow"}],
      "updated": 1690295874454, "link": null, "locked": false
    },
    {
      "id": "label-a", "type": "text",
      "x": 145, "y": 127.5, "width": 90, "height": 25,
      "angle": 0, "strokeColor": "#1e1e1e", "backgroundColor": "transparent",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 1, "opacity": 100, "seed": 2345678,
      "version": 1, "versionNonce": 0, "isDeleted": false,
      "groupIds": [], "frameId": null, "roundness": null,
      "boundElements": null, "updated": 1690295874454, "link": null, "locked": false,
      "text": "Start", "originalText": "Start",
      "fontSize": 20, "fontFamily": 5, "textAlign": "center", "verticalAlign": "middle",
      "containerId": "box-a", "autoResize": true, "lineHeight": 1.25
    },
    {
      "id": "box-b", "type": "rectangle",
      "x": 420, "y": 100, "width": 180, "height": 80,
      "angle": 0, "strokeColor": "#1e1e1e", "backgroundColor": "#b2f2bb",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 1, "opacity": 100, "seed": 3456789,
      "version": 1, "versionNonce": 0, "isDeleted": false,
      "groupIds": [], "frameId": null, "roundness": {"type": 3},
      "boundElements": [{"id": "arrow-1", "type": "arrow"}],
      "updated": 1690295874454, "link": null, "locked": false
    },
    {
      "id": "arrow-1", "type": "arrow",
      "x": 285, "y": 140, "width": 130, "height": 0,
      "angle": 0, "strokeColor": "#1e1e1e", "backgroundColor": "transparent",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "roughness": 1, "opacity": 100, "seed": 4567890,
      "version": 1, "versionNonce": 0, "isDeleted": false,
      "groupIds": [], "frameId": null, "roundness": {"type": 2},
      "boundElements": null, "updated": 1690295874454, "link": null, "locked": false,
      "points": [[0, 0], [130, 0]],
      "lastCommittedPoint": null,
      "startBinding": {"elementId": "box-a", "focus": 0, "gap": 5},
      "endBinding": {"elementId": "box-b", "focus": 0, "gap": 5},
      "startArrowhead": null, "endArrowhead": "arrow", "elbowed": false
    }
  ],
  "appState": {"gridSize": 20, "viewBackgroundColor": "#ffffff"},
  "files": {}
}
```
