#!/usr/bin/env python3
"""Push a .excalidraw file to an Excalidraw+ workspace via the REST API. Stdlib only.

Usage:
  push.py <file.excalidraw> --name "Scene name"     # create in default collection
  push.py <file.excalidraw> --scene <sceneId>       # replace an existing scene's content

Auth: EXCALIDRAW_API_KEY env var, else ~/.config/excalidraw/api_key.

The API is stricter than the app's file loader: it requires the full document
wrapper, a fractional `index` string on every element, and v2 arrow bindings
carrying `fixedPoint` + `mode`. This script adds all three, leaving the input
file untouched.
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

API = "https://api.excalidraw.com/api/v1"
DIGITS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"


def api_key():
    if os.environ.get("EXCALIDRAW_API_KEY"):
        return os.environ["EXCALIDRAW_API_KEY"]
    path = Path.home() / ".config" / "excalidraw" / "api_key"
    if path.exists():
        return path.read_text().strip()
    sys.exit("No API key: set EXCALIDRAW_API_KEY or create ~/.config/excalidraw/api_key")


def request(method, path, body=None):
    req = urllib.request.Request(
        API + path,
        method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={"Authorization": f"Bearer {api_key()}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as e:
        sys.exit(f"{method} {path} -> HTTP {e.code}\n{e.read().decode()[:2000]}")


def prepare(doc):
    """Return API-shaped content: indices + v2 bindings added."""
    elements = [dict(el) for el in doc["elements"]]
    by_id = {el["id"]: el for el in elements}

    for i, el in enumerate(elements):
        if not el.get("index"):
            el["index"] = "b" + DIGITS[i // 62] + DIGITS[i % 62]

    def upgrade(arrow, key, point):
        b = arrow.get(key)
        if not b or b.get("elementId") not in by_id:
            return
        b = dict(b)
        target = by_id[b["elementId"]]
        if target.get("width") and target.get("height"):
            px = arrow.get("x", 0) + point[0]
            py = arrow.get("y", 0) + point[1]
            b["fixedPoint"] = [
                round(min(1.0, max(0.0, (px - target["x"]) / target["width"])), 4),
                round(min(1.0, max(0.0, (py - target["y"]) / target["height"])), 4),
            ]
        else:
            b["fixedPoint"] = [0.5, 0.5]
        b.setdefault("mode", "orbit")
        arrow[key] = b

    for el in elements:
        if el.get("type") == "arrow" and el.get("points"):
            upgrade(el, "startBinding", el["points"][0])
            upgrade(el, "endBinding", el["points"][-1])

    return {
        "type": "excalidraw",
        "version": doc.get("version", 2),
        "source": doc.get("source", "https://excalidraw.com"),
        "elements": elements,
        "appState": doc.get("appState", {}),
        "files": doc.get("files", {}),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("file")
    parser.add_argument("--name", help="create a new scene with this name")
    parser.add_argument("--scene", help="update this existing scene id instead")
    parser.add_argument("--collection", help="collection id (default: workspace default)")
    args = parser.parse_args()
    if not args.name and not args.scene:
        sys.exit("Pass --name (create) or --scene <id> (update)")

    doc = json.loads(Path(args.file).read_text(encoding="utf-8"))
    content = prepare(doc)

    scene_id = args.scene
    if not scene_id:
        collection = args.collection
        if not collection:
            collections = request("GET", "/collections")["data"]
            collection = next((c["id"] for c in collections if c.get("isDefault")), collections[0]["id"])
        created = request("POST", f"/collections/{collection}/scenes", {"name": args.name, "pinned": False})
        scene_id = created["metadata"]["id"]

    request("PUT", f"/scenes/{scene_id}/content", content)
    meta = request("GET", f"/scenes/{scene_id}")["metadata"]
    print(f"{meta['name']}: {meta['totalElements']} elements")
    print(f"https://app.excalidraw.com/s/{meta['workspace']}/{scene_id}")


if __name__ == "__main__":
    main()
