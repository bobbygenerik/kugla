#!/usr/bin/env python3
"""Letterbox rectangular master art to 1024² and horizontally center visual mass.

  python3 tools/pack_square_app_icon.py
  dart run flutter_launcher_icons

Default input: assets/icon/kugla_app_icon_source_rect.png
Outputs: assets/icon/kugla_app_icon_ios.png, kugla_app_icon_foreground.png
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SRC = ROOT / "assets" / "icon" / "kugla_app_icon_source_rect.png"
IOS_OUT = ROOT / "assets" / "icon" / "kugla_app_icon_ios.png"
FG_OUT = ROOT / "assets" / "icon" / "kugla_app_icon_foreground.png"

CANVAS = 1024
BG = (12, 30, 40)  # #0C1E28 — adaptive_icon_background


def horizontal_paste_x(rgb: np.ndarray) -> int:
    """Pixels to shift art left (negative) so weighted foreground centers on canvas."""
    h, w = rgb.shape[:2]
    gray = rgb.mean(axis=2)
    bg_level = np.percentile(gray, 5)
    mask = gray > bg_level + 8
    wts = (gray - bg_level).clip(0, None)
    wts[~mask] = 0
    if wts.sum() <= 0:
        return 0
    yy, xx = np.indices(gray.shape)
    cx = (xx * wts).sum() / wts.sum()
    dx = int(round(CANVAS / 2 - cx))
    return max(-40, min(40, dx))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("src", nargs="?", type=Path, default=DEFAULT_SRC)
    args = ap.parse_args()
    src: Path = args.src
    if not src.is_file():
        raise SystemExit(f"Missing {src}")

    im = Image.open(src).convert("RGB")
    w, h = im.size
    if w != CANVAS or h > CANVAS:
        raise SystemExit(f"Expected width {CANVAS} and height ≤ {CANVAS}, got {w}x{h}")

    arr = np.array(im)
    paste_x = horizontal_paste_x(arr)
    top = (CANVAS - h) // 2

    canvas = Image.new("RGB", (CANVAS, CANVAS), BG)
    canvas.paste(im, (paste_x, top))
    canvas.save(IOS_OUT, optimize=True)
    print(f"Wrote {IOS_OUT.relative_to(ROOT)} (paste_x={paste_x})")

    rgba = Image.new("RGBA", (CANVAS, CANVAS), BG + (255,))
    rgba.paste(im, (paste_x, top))
    rgba.save(FG_OUT, optimize=True)
    print(f"Wrote {FG_OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
