#!/usr/bin/env python3
"""Pull a scene from an Excalidraw+ workspace into a local .excalidraw file. Stdlib only.

Usage: pull.py <sceneId-or-url> [output.excalidraw]

Strips API-only fields (`index`, binding `fixedPoint`/`mode`) so the file
matches the released app's file format; push.py re-adds them on upload.
"""

import argparse
import json
import sys
from pathlib import Path

from excalidraw_api import request, scene_id_from


def to_file_format(content):
    for el in content.get("elements", []):
        el.pop("index", None)
        for key in ("startBinding", "endBinding"):
            b = el.get(key)
            if isinstance(b, dict):
                b.pop("fixedPoint", None)
                b.pop("mode", None)
                b.setdefault("focus", 0)
                b.setdefault("gap", 4)
    return {
        "type": "excalidraw",
        "version": content.get("version", 2),
        "source": content.get("source", "https://excalidraw.com"),
        "elements": content.get("elements", []),
        "appState": content.get("appState", {}),
        "files": content.get("files", {}),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("scene")
    parser.add_argument("output", nargs="?")
    args = parser.parse_args()

    scene_id = scene_id_from(args.scene)
    content = request("GET", f"/scenes/{scene_id}/content")
    doc = to_file_format(content)
    out = Path(args.output) if args.output else Path(f"{scene_id}.excalidraw")
    out.write_text(json.dumps(doc, indent=1), encoding="utf-8")
    print(f"{out} ({len(doc['elements'])} elements)", file=sys.stderr)
    print(out)


if __name__ == "__main__":
    main()
