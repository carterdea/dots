#!/usr/bin/env python3
"""Validate a .excalidraw file. Stdlib only.

Usage: validate.py <file.excalidraw> [--strict]

ERROR  = will break, vanish, or visibly misrender when opened in Excalidraw.
WARN   = loads, but likely looks wrong or loses intent.
Exit 1 on errors (or on warnings with --strict), else 0.
"""

import json
import math
import sys

KNOWN_TYPES = {
    "rectangle", "ellipse", "diamond", "text", "line", "arrow",
    "freedraw", "image", "frame", "magicframe", "embeddable", "iframe",
}
SHAPES = {"rectangle", "ellipse", "diamond"}
TEXT_CONTAINERS = {"rectangle", "ellipse", "diamond", "arrow"}
ARROW_TARGETS = {"rectangle", "ellipse", "diamond", "text", "image", "frame", "embeddable", "iframe"}
FILL_STYLES = {"solid", "hachure", "cross-hatch", "zigzag"}
STROKE_STYLES = {"solid", "dashed", "dotted"}
TEXT_ALIGNS = {"left", "center", "right"}
VERTICAL_ALIGNS = {"top", "middle", "bottom"}
ARROWHEADS = {
    "arrow", "bar", "circle", "circle_outline", "triangle", "triangle_outline",
    "diamond", "diamond_outline", "crowfoot_one", "crowfoot_many", "crowfoot_one_or_many",
}
FONT_FAMILIES = {1, 2, 3, 5, 6, 7, 8, 9}

errors: list[str] = []
warnings: list[str] = []


def err(el, msg):
    errors.append(f"ERROR {label(el)}: {msg}")


def warn(el, msg):
    warnings.append(f"WARN  {label(el)}: {msg}")


def label(el):
    if el is None:
        return "file"
    return f"{el.get('type', '?')} id={el.get('id', '?')}"


def is_num(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def bbox(el):
    """Absolute bounding box (x0, y0, x1, y1)."""
    x, y = el.get("x", 0), el.get("y", 0)
    if el.get("type") in ("arrow", "line", "freedraw") and el.get("points"):
        xs = [x + p[0] for p in el["points"]]
        ys = [y + p[1] for p in el["points"]]
        return min(xs), min(ys), max(xs), max(ys)
    return x, y, x + abs(el.get("width", 0)), y + abs(el.get("height", 0))


def segment_hits_rect(p0, p1, rect, inset=4.0):
    """Liang-Barsky: does the segment cross the rect's interior (shrunk by inset)?"""
    x0, y0, x1, y1 = rect
    x0 += inset; y0 += inset; x1 -= inset; y1 -= inset
    if x1 <= x0 or y1 <= y0:
        return False
    px, py = p0
    dx, dy = p1[0] - px, p1[1] - py
    t0, t1 = 0.0, 1.0
    for p, q in ((-dx, px - x0), (dx, x1 - px), (-dy, py - y0), (dy, y1 - py)):
        if p == 0:
            if q < 0:
                return False
        else:
            r = q / p
            if p < 0:
                if r > t1:
                    return False
                t0 = max(t0, r)
            else:
                if r < t0:
                    return False
                t1 = min(t1, r)
    return t0 <= t1


def abs_points(el):
    ax, ay = el.get("x", 0), el.get("y", 0)
    pts = []
    for p in el.get("points") or []:
        if isinstance(p, list) and len(p) == 2 and is_num(p[0]) and is_num(p[1]):
            pts.append((ax + p[0], ay + p[1]))
    return pts


def overlap_area(a, b):
    w = min(a[2], b[2]) - max(a[0], b[0])
    h = min(a[3], b[3]) - max(a[1], b[1])
    return w * h if w > 0 and h > 0 else 0


def text_area_in(container, font_size):
    """Available (width, height) for bound text, per Excalidraw's formulas."""
    w, h = container.get("width", 0), container.get("height", 0)
    t = container["type"]
    if t == "ellipse":
        return round(w / 2 * math.sqrt(2)) - 10, round(h / 2 * math.sqrt(2)) - 10
    if t == "diamond":
        return round(w / 2) - 10, round(h / 2) - 10
    if t == "arrow":
        return max(0.7 * w, font_size * 11), h
    return w - 10, h - 10


def check_element(el):
    t = el.get("type")
    if not isinstance(el.get("id"), str) or not el["id"]:
        err(el, "missing or non-string id")
    for key in ("x", "y", "width", "height"):
        if key in el and not is_num(el[key]):
            err(el, f"{key} must be a finite number, got {el[key]!r}")

    if "opacity" in el and not (is_num(el["opacity"]) and 0 <= el["opacity"] <= 100):
        err(el, f"opacity must be 0-100, got {el.get('opacity')!r}")
    if el.get("fillStyle") is not None and el.get("fillStyle") not in FILL_STYLES:
        err(el, f"invalid fillStyle {el['fillStyle']!r} (valid: {sorted(FILL_STYLES)})")
    if el.get("strokeStyle") is not None and el.get("strokeStyle") not in STROKE_STYLES:
        err(el, f"invalid strokeStyle {el['strokeStyle']!r}")
    r = el.get("roundness")
    if r is not None and (not isinstance(r, dict) or r.get("type") not in (1, 2, 3)):
        err(el, f"roundness must be null or {{\"type\": 1|2|3}}, got {r!r}")

    if el.get("strokeWidth") == 0:
        warn(el, "strokeWidth 0 is falsy and gets replaced with the default (2) on load")
    if el.get("strokeColor") == "":
        warn(el, 'strokeColor "" is falsy and gets replaced with the default on load')
    if el.get("index") is not None:
        warn(el, "hand-written index is risky; omit it (Excalidraw reassigns from array order)")

    be = el.get("boundElements")
    if be is not None:
        if not isinstance(be, list):
            err(el, "boundElements must be null or an array")
        else:
            for entry in be:
                if not isinstance(entry, dict) or entry.get("type") not in ("arrow", "text"):
                    err(el, f'boundElements entry needs type "arrow"|"text": {entry!r}')

    if t == "text":
        check_text(el)
    elif t in ("arrow", "line"):
        check_linear(el)
    elif t == "image":
        if not el.get("fileId"):
            err(el, "image element missing fileId")


def check_text(el):
    text = el.get("text")
    if not isinstance(text, str):
        err(el, "text element missing text string")
        return
    if text == "":
        warn(el, "empty text is deleted on load")
    if el.get("originalText") not in (None, text) and "\n" not in text:
        warn(el, "originalText differs from text on unwrapped text")
    ff = el.get("fontFamily")
    if ff is not None and ff not in FONT_FAMILIES:
        warn(el, f"fontFamily {ff!r} is not a released code (valid: {sorted(FONT_FAMILIES)}); renders as fallback font")
    if el.get("textAlign") is not None and el["textAlign"] not in TEXT_ALIGNS:
        err(el, f"invalid textAlign {el['textAlign']!r}")
    if el.get("verticalAlign") is not None and el["verticalAlign"] not in VERTICAL_ALIGNS:
        err(el, f"invalid verticalAlign {el['verticalAlign']!r}")

    font_size = el.get("fontSize", 20)
    line_height = el.get("lineHeight", 1.25)
    lines = text.split("\n")
    if is_num(el.get("height")) and is_num(font_size):
        expected_h = font_size * line_height * len(lines)
        if abs(el["height"] - expected_h) > 3:
            warn(el, f"height {el['height']} != fontSize*lineHeight*lines = {expected_h:.1f}")
    if is_num(el.get("width")) and is_num(font_size) and lines:
        per_char = 0.6 if el.get("fontFamily") == 3 else 0.5
        est = max(len(line) for line in lines) * per_char * font_size
        if est > 0 and not (0.5 * est <= el["width"] <= 1.7 * est):
            warn(el, f"width {el['width']} looks off for the text (rough estimate {est:.0f}); "
                     "wrong widths are not repaired on load and misalign centered/bound text")


def check_linear(el):
    pts = el.get("points")
    if not isinstance(pts, list) or len(pts) < 2:
        err(el, "arrow/line needs a points array with at least 2 [x,y] points")
        return
    for p in pts:
        if not (isinstance(p, list) and len(p) == 2 and is_num(p[0]) and is_num(p[1])):
            err(el, f"invalid point {p!r}")
            return
    if pts[0] != [0, 0]:
        warn(el, f"points[0] should be [0,0], got {pts[0]} (Excalidraw rebases it on load)")
    ext_w = max(p[0] for p in pts) - min(p[0] for p in pts)
    ext_h = max(p[1] for p in pts) - min(p[1] for p in pts)
    if is_num(el.get("width")) and (abs(el["width"] - ext_w) > 1 or abs(el.get("height", 0) - ext_h) > 1):
        warn(el, f"width/height ({el.get('width')},{el.get('height')}) don't match points extent ({ext_w},{ext_h}); recomputed on load")

    for key in ("startArrowhead", "endArrowhead"):
        v = el.get(key)
        if v is not None and v not in ARROWHEADS:
            warn(el, f"{key} {v!r} not in the safe set {sorted(ARROWHEADS)}; renders as nothing")

    if el["type"] == "line":
        for key in ("startBinding", "endBinding"):
            if el.get(key) is not None:
                err(el, f"lines cannot bind; {key} is nulled on load")
    else:
        for key in ("startBinding", "endBinding"):
            b = el.get(key)
            if b is None:
                continue
            if not isinstance(b, dict) or not b.get("elementId"):
                err(el, f"{key} must be null or {{elementId, focus, gap}}")
            elif "fixedPoint" in b or "mode" in b:
                err(el, f"{key} uses the master-only fixedPoint/mode format; write {{elementId, focus, gap}}")
            elif b.get("gap") is not None and (not is_num(b["gap"]) or b["gap"] <= 0):
                warn(el, f"{key}.gap should be > 0")


def check_cross_references(elements, files):
    by_id = {}
    for el in elements:
        el_id = el.get("id")
        if el_id in by_id:
            err(el, "duplicate id")
        elif el_id:
            by_id[el_id] = el

    def alive(el_id):
        el = by_id.get(el_id)
        return el if el is not None and not el.get("isDeleted") else None

    for el in elements:
        t = el.get("type")

        for entry in el.get("boundElements") or []:
            if not isinstance(entry, dict):
                continue
            target = alive(entry.get("id"))
            if target is None:
                err(el, f"boundElements references missing/deleted element {entry.get('id')!r}")
            elif entry.get("type") == "text" and target.get("containerId") != el.get("id"):
                warn(el, f"bound text {target['id']!r} does not point back via containerId (healed on load)")
            elif entry.get("type") == "arrow":
                bindings = [target.get("startBinding"), target.get("endBinding")]
                if not any(isinstance(b, dict) and b.get("elementId") == el.get("id") for b in bindings):
                    warn(el, f"boundElements lists arrow {target['id']!r} but the arrow does not bind back to this element")

        if t == "text" and el.get("containerId"):
            container = alive(el["containerId"])
            if container is None:
                err(el, f"containerId {el['containerId']!r} missing/deleted (cleared on load)")
            else:
                if container.get("type") not in TEXT_CONTAINERS:
                    err(el, f"container {container['id']!r} is a {container.get('type')!r}; text binds only to {sorted(TEXT_CONTAINERS)}")
                entries = container.get("boundElements") or []
                if not any(isinstance(e, dict) and e.get("id") == el["id"] for e in entries):
                    warn(el, f"container {container['id']!r} missing reciprocal boundElements entry (healed on load)")
                check_text_fit(el, container)

        if t == "arrow":
            for key in ("startBinding", "endBinding"):
                b = el.get(key)
                if not isinstance(b, dict) or not b.get("elementId"):
                    continue
                target = alive(b["elementId"])
                if target is None:
                    err(el, f"{key} references missing/deleted element {b['elementId']!r} (nulled on load)")
                    continue
                if target.get("type") not in ARROW_TARGETS:
                    warn(el, f"{key} targets a {target.get('type')!r}, which is not bindable")
                    continue
                entries = target.get("boundElements") or []
                if not any(isinstance(e, dict) and e.get("id") == el.get("id") for e in entries):
                    warn(el, f"{key} target {target['id']!r} missing reciprocal boundElements entry")
                check_arrow_endpoint(el, key, target)

        if el.get("frameId") is not None:
            frame = alive(el["frameId"])
            if frame is None or frame.get("type") not in ("frame", "magicframe"):
                err(el, f"frameId {el['frameId']!r} does not resolve to a frame")

        if t == "image" and el.get("fileId") and el["fileId"] not in files:
            err(el, f"fileId {el['fileId']!r} not present in top-level files")


def check_text_fit(text_el, container):
    avail_w, avail_h = text_area_in(container, text_el.get("fontSize", 20))
    tw, th = text_el.get("width", 0), text_el.get("height", 0)
    if is_num(tw) and tw > avail_w + 1:
        warn(text_el, f"text width {tw} exceeds container {container['id']!r} text area ({avail_w:.0f}); will overflow")
    if is_num(th) and container["type"] != "arrow" and th > avail_h + 1:
        warn(text_el, f"text height {th} exceeds container {container['id']!r} text area ({avail_h:.0f}); will overflow")
    if container["type"] in SHAPES and text_el.get("textAlign", "center") == "center":
        cx = container.get("x", 0) + (container.get("width", 0) - tw) / 2
        cy = container.get("y", 0) + (container.get("height", 0) - th) / 2
        if abs(text_el.get("x", 0) - cx) > 2 or abs(text_el.get("y", 0) - cy) > 2:
            warn(text_el, f"bound text x/y not centered in {container['id']!r} "
                          f"(expected ~({cx:.1f}, {cy:.1f})); stored position is used as-is when rendering")


def check_arrow_endpoint(arrow, key, target):
    pts = arrow.get("points")
    if not isinstance(pts, list) or len(pts) < 2:
        return
    end, prev = (pts[0], pts[1]) if key == "startBinding" else (pts[-1], pts[-2])
    for p in (end, prev):
        if not (isinstance(p, list) and len(p) == 2 and is_num(p[0]) and is_num(p[1])):
            return
    ax, ay = arrow.get("x", 0), arrow.get("y", 0)
    px, py = ax + end[0], ay + end[1]
    rect = bbox(target)
    x0, y0, x1, y1 = rect
    pad = 0.2 * max(x1 - x0, y1 - y0) + 30
    if not (x0 - pad <= px <= x1 + pad and y0 - pad <= py <= y1 + pad):
        warn(arrow, f"{key} endpoint ({px:.0f}, {py:.0f}) is far from target {target['id']!r} "
                    f"bbox ({x0:.0f}, {y0:.0f})-({x1:.0f}, {y1:.0f})")
        return
    # The final segment should stop at the near edge; if it cuts the interior,
    # the drawn line runs through the shape to reach the far side.
    qx, qy = ax + prev[0], ay + prev[1]
    if segment_hits_rect((qx, qy), (px, py), rect, inset=6):
        warn(arrow, f"{key} segment passes through target {target['id']!r} "
                    "instead of stopping at its near edge")


def check_arrow_crossings(elements):
    """Arrows that cut through shapes they are not bound to."""
    shapes = [e for e in elements if e.get("type") in SHAPES and not e.get("isDeleted")]
    for el in elements:
        if el.get("type") != "arrow" or el.get("isDeleted"):
            continue
        pts = abs_points(el)
        if len(pts) < 2:
            continue
        bound = {b.get("elementId") for b in (el.get("startBinding"), el.get("endBinding"))
                 if isinstance(b, dict)}
        for shape in shapes:
            if shape.get("id") in bound:
                continue
            rect = bbox(shape)
            if any(segment_hits_rect(pts[i], pts[i + 1], rect) for i in range(len(pts) - 1)):
                warn(el, f"crosses {label(shape)}")


def check_overlaps(elements):
    def related(a, b):
        if set(a.get("groupIds") or []) & set(b.get("groupIds") or []):
            return True
        ids = (a.get("id"), b.get("id"))
        return a.get("containerId") in ids or b.get("containerId") in ids or \
            a.get("frameId") in ids or b.get("frameId") in ids

    visible = [e for e in elements if not e.get("isDeleted")]
    shapes = [e for e in visible if e.get("type") in SHAPES]
    texts = [e for e in visible if e.get("type") == "text"]

    for group, kind in ((shapes, "shapes"), (texts, "text elements")):
        for i, a in enumerate(group):
            for b in group[i + 1:]:
                if related(a, b):
                    continue
                area = overlap_area(bbox(a), bbox(b))
                if area > 25:
                    warn(a, f"overlaps {label(b)} by {area:.0f}px² ({kind})")

    for text in texts:
        if text.get("containerId"):
            continue
        tb = bbox(text)
        for shape in shapes:
            if related(text, shape):
                continue
            sb = bbox(shape)
            if overlap_area(tb, sb) > 25 and not (
                sb[0] <= tb[0] and tb[2] <= sb[2] and sb[1] <= tb[1] and tb[3] <= sb[3]
            ):
                warn(text, f"partially overlaps {label(shape)} without being inside or bound to it")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    strict = "--strict" in sys.argv
    if len(args) != 1:
        print(__doc__.strip(), file=sys.stderr)
        sys.exit(2)

    try:
        with open(args[0], encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        print(f"ERROR file: {e}", file=sys.stderr)
        sys.exit(1)

    if data.get("type") != "excalidraw":
        err(None, f'top-level type must be "excalidraw", got {data.get("type")!r}')
    elements = data.get("elements")
    if not isinstance(elements, list):
        err(None, "elements must be an array")
        elements = []
    elif not elements:
        warn(None, "elements array is empty")
    if "appState" in data and not isinstance(data["appState"], dict):
        err(None, "appState must be an object")

    for el in elements:
        if not isinstance(el, dict):
            err(None, f"element is not an object: {el!r}")
            continue
        t = el.get("type")
        if t == "selection":
            err(el, "selection elements are filtered out on load; remove it")
        elif t not in KNOWN_TYPES:
            err(el, f"unknown type {t!r} — Excalidraw silently drops it")
        else:
            check_element(el)

    dict_elements = [e for e in elements if isinstance(e, dict)]
    check_cross_references(dict_elements, data.get("files") or {})
    check_overlaps(dict_elements)
    check_arrow_crossings(dict_elements)

    for line in errors + warnings:
        print(line)
    n = len(dict_elements)
    print(f"{args[0]}: {n} element(s), {len(errors)} error(s), {len(warnings)} warning(s)")
    sys.exit(1 if errors or (strict and warnings) else 0)


if __name__ == "__main__":
    main()
