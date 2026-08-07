"""Shared Excalidraw+ REST API helpers. Stdlib only.

Auth: EXCALIDRAW_API_KEY env var, else ~/.config/excalidraw/api_key.
"""

import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

API = "https://api.excalidraw.com/api/v1"


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


def scene_id_from(ref):
    """Accept a bare scene id or an app.excalidraw.com scene URL."""
    return ref.rstrip("/").split("/")[-1].split("?")[0]
