#!/usr/bin/env python3
"""Legacy: center-crop a photo to 1024² for launcher experiments.

**Shipped icons:** use `tools/build_app_icon.py` (single globe + opaque pin, no
raster stack). Do not run this unless you intentionally replace assets from a
flat master.

Primary source: uploads/kuglafixed.jpg, or assets/icon/kugla_app_icon.png.

  python3 tools/generate_app_icons.py   # optional / legacy
  dart run flutter_launcher_icons
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_JPG = ROOT / "uploads" / "kuglafixed.jpg"
LEGACY_PNG = ROOT / "assets" / "icon" / "kugla_app_icon.png"
FG_OUT = ROOT / "assets" / "icon" / "kugla_app_icon_foreground.png"
IOS_OUT = ROOT / "assets" / "icon" / "kugla_app_icon_ios.png"

CANVAS = 1024

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

    alpha_u8 = np.full((h, w), 255, dtype=np.uint8)
    rgba = np.dstack([a.astype(np.uint8), alpha_u8])
    Image.fromarray(rgba, "RGBA").save(FG_OUT)
    print(f"Wrote {FG_OUT.relative_to(ROOT)}")

    # iOS / legacy mipmap: same full-bleed square (no shrinking, no bars).
    Image.fromarray(a.astype(np.uint8), "RGB").save(IOS_OUT)
    print(f"Wrote {IOS_OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
