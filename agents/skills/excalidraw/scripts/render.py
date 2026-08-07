#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["playwright>=1.40"]
# ///
"""Render a .excalidraw file to PNG using Excalidraw's own exportToSvg in headless Chromium.

Usage: uv run render.py <file.excalidraw> [--output out.png] [--scale 2]
First run only: uv run --with playwright playwright install chromium
Requires network (loads the pinned @excalidraw/excalidraw bundle from esm.sh).
"""

import argparse
import json
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("file")
    parser.add_argument("--output", help="PNG path (default: alongside input)")
    parser.add_argument("--scale", type=int, default=2, help="device scale factor")
    args = parser.parse_args()

    src = Path(args.file)
    data = json.loads(src.read_text(encoding="utf-8"))
    out = Path(args.output) if args.output else src.with_suffix(".png")
    template = (Path(__file__).parent / "render_template.html").resolve().as_uri()

    with sync_playwright() as pw:
        browser = pw.chromium.launch()
        page = browser.new_page(device_scale_factor=args.scale)
        page.goto(template)
        page.wait_for_function("window.__moduleReady === true", timeout=60000)
        page.evaluate("data => window.renderDiagram(data)", data)
        page.wait_for_function("window.__renderComplete === true", timeout=30000)
        render_error = page.evaluate("window.__renderError")
        if render_error:
            print(f"Render failed: {render_error}", file=sys.stderr)
            sys.exit(1)
        svg = page.wait_for_selector("#root svg")
        svg.screenshot(path=str(out))
        browser.close()

    print(out)


if __name__ == "__main__":
    main()
