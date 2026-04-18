#!/usr/bin/env python3
"""Build adaptive foreground (RGBA) + iOS full-bleed (RGB) from the Kugla logo.

The master image is center-cropped to a square (cover / scale-to-fill) so every
pixel of the 1024×1024 asset is artwork — no letterboxing. Launcher masks
(circle, squircle, etc.) are still applied by the OS.

Primary source: uploads/kuglafixed.jpg (official mark). Falls back to
assets/icon/kugla_app_icon.png if the JPG is missing.

Run from repo root:
  python3 tools/generate_app_icons.py
  dart run flutter_launcher_icons
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE_JPG = ROOT / "uploads" / "kuglafixed.jpg"
LEGACY_PNG = ROOT / "assets" / "icon" / "kugla_app_icon.png"
FG_OUT = ROOT / "assets" / "icon" / "kugla_app_icon_foreground.png"
IOS_OUT = ROOT / "assets" / "icon" / "kugla_app_icon_ios.png"

CANVAS = 1024

# Soft matte: max RGB channel delta from edge reference → alpha.
T0, T1 = 10.0, 32.0


def resolve_master() -> Path:
    if SOURCE_JPG.is_file():
        return SOURCE_JPG
    if LEGACY_PNG.is_file():
        return LEGACY_PNG
    raise SystemExit(
        f"No master logo found. Add {SOURCE_JPG} or {LEGACY_PNG}."
    )


def cover_center_crop_square(im: Image.Image, size: int) -> Image.Image:
    """Scale [im] uniformly so it covers size×size, then center-crop. No letterboxing."""
    im = im.convert("RGB")
    w, h = im.size
    scale = max(size / w, size / h)
    nw, nh = max(1, int(round(w * scale))), max(1, int(round(h * scale)))
    im = im.resize((nw, nh), Image.Resampling.LANCZOS)
    ox = (nw - size) // 2
    oy = (nh - size) // 2
    return im.crop((ox, oy, ox + size, oy + size))


def main() -> None:
    master_path = resolve_master()
    print(f"Using master: {master_path.relative_to(ROOT)}")

    square = cover_center_crop_square(Image.open(master_path), CANVAS)
    a = np.array(square, dtype=np.float32)
    h, w = a.shape[:2]

    border = np.concatenate([a[0, :], a[-1, :], a[:, 0], a[:, -1]], axis=0)
    ref = np.median(border, axis=0)
    d = np.abs(a - ref).max(axis=2)

    alpha = np.clip((d - T0) / (T1 - T0), 0.0, 1.0)
    alpha_u8 = (alpha * 255.0).astype(np.uint8)
    alpha_im = Image.fromarray(alpha_u8, mode="L")
    alpha_im = alpha_im.filter(ImageFilter.GaussianBlur(radius=0.85))
    alpha_blur = np.array(alpha_im, dtype=np.uint8)

    rgba = np.dstack([a.astype(np.uint8), alpha_blur])
    Image.fromarray(rgba, "RGBA").save(FG_OUT)
    print(f"Wrote {FG_OUT.relative_to(ROOT)}")

    # iOS / legacy mipmap: same full-bleed square (no shrinking, no bars).
    Image.fromarray(a.astype(np.uint8), "RGB").save(IOS_OUT)
    print(f"Wrote {IOS_OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
