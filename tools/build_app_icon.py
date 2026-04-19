#!/usr/bin/env python3
"""Kugla launcher icon — built from scratch (no legacy master art).

  • solid midnight square
  • one orthographic Natural Earth globe (flat ocean / flat land — no soft coast)
  • vector map pin: ellipse head + triangle body (solid fills, no pieslice glitches)

Layout: large orthographic globe (majority of frame); map pin tip sits on the visible
map (not on the north “cap”), with head offset along the surface normal. Scaled inset
for adaptive squircle safe zone.

  python3 tools/build_app_icon.py
  dart run flutter_launcher_icons
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
GEOJSON = ROOT / "tools" / "data" / "ne_110m_land.geojson"
IOS_OUT = ROOT / "assets" / "icon" / "kugla_app_icon_ios.png"
FG_OUT = ROOT / "assets" / "icon" / "kugla_app_icon_foreground.png"

CANVAS = 1024

LON0_DEG = -28.0
LAT0_DEG = 18.0

# Globe: dominant element; center slightly below mid so pin + highlight stay balanced.
GCX = 512.0
GCY = 548.0
R_GLOBE = 395.0

# Pin tip on globe: degrees clockwise from “up” (0° = top of icon); ~38° puts the mark
# on the upper-right map (e.g. Europe / Atlantic) instead of the north pole.
PIN_ANGLE_DEG = 38.0

MIDNIGHT = np.array([12, 30, 40], dtype=np.float32)  # #0C1E28
OCEAN_RGB = np.array([44.0, 114.0, 187.0], dtype=np.float32)
LAND_RGB = np.array([78.0, 185.0, 100.0], dtype=np.float32)

PIN_ORANGE = (232, 108, 52)
PIN_HIGHLIGHT = (255, 218, 188)
PIN_WHITE = (255, 255, 255)
PIN_HOLE = (24, 56, 96)

# Slight inset only — globe already fills canvas; keeps limb inside adaptive keyline.
SAFE_SCALE = 0.86


def deg2rad(d: float) -> float:
    return d * math.pi / 180.0


def make_project_fn(cx: float, cy: float, r_ortho: float):
    def project_ortho(lon_deg: float, lat_deg: float) -> tuple[float, float] | None:
        lam = deg2rad(lon_deg)
        phi = deg2rad(lat_deg)
        lam0 = deg2rad(LON0_DEG)
        phi0 = deg2rad(LAT0_DEG)
        sinphi, cosphi = math.sin(phi), math.cos(phi)
        cos_lam = math.cos(lam - lam0)
        cos_c = math.sin(phi0) * sinphi + math.cos(phi0) * cosphi * cos_lam
        if cos_c < -0.02:
            return None
        x = cosphi * math.sin(lam - lam0)
        y = math.cos(phi0) * sinphi - math.sin(phi0) * cosphi * cos_lam
        return (cx + x * r_ortho, cy - y * r_ortho)

    return project_ortho


def subsample_ring(
    coords: list,
    project_ortho,
    max_pts: int = 450,
) -> list[tuple[float, float]]:
    if len(coords) <= max_pts:
        out = coords
    else:
        step = max(1, len(coords) // max_pts)
        out = coords[::step] + [coords[-1]]
    ring: list[tuple[float, float]] = []
    for c in out:
        lon, lat = float(c[0]), float(c[1])
        p = project_ortho(lon, lat)
        if p is not None:
            ring.append(p)
    return ring


def draw_polygon_with_holes(
    draw: ImageDraw.ImageDraw,
    poly_coords: list,
    project_ortho,
) -> None:
    if not poly_coords:
        return
    exterior = subsample_ring(poly_coords[0], project_ortho)
    if len(exterior) >= 3:
        draw.polygon(exterior, fill=255)
    for hole in poly_coords[1:]:
        h = subsample_ring(hole, project_ortho)
        if len(h) >= 3:
            draw.polygon(h, fill=0)


def build_land_mask(project_ortho) -> Image.Image:
    with open(GEOJSON, encoding="utf-8") as f:
        data = json.load(f)

    mask = Image.new("L", (CANVAS, CANVAS), 0)
    draw = ImageDraw.Draw(mask)

    for feat in data["features"]:
        geom = feat.get("geometry")
        if geom is None:
            continue
        gtype = geom["type"]
        coords = geom["coordinates"]
        if gtype == "Polygon":
            draw_polygon_with_holes(draw, coords, project_ortho)
        elif gtype == "MultiPolygon":
            for poly in coords:
                draw_polygon_with_holes(draw, poly, project_ortho)

    return mask


def draw_map_pin(
    im: Image.Image,
    cx: float,
    cy: float,
    r_globe: float,
    angle_deg: float,
) -> None:
    """Cartoon map pin: tip on globe surface, body along outward radial; solid fills."""
    drw = ImageDraw.Draw(im)
    phi = math.radians(angle_deg)
    # Unit from globe center toward tip (screen coords, +y down).
    ux = math.sin(phi)
    uy = -math.cos(phi)

    # Tip slightly inside disk so it reads clearly on land/ocean.
    k_tip = 0.74
    tip_x = cx + r_globe * k_tip * ux
    tip_y = cy + r_globe * k_tip * uy

    r_head = max(36, int(round(r_globe * 0.125)))
    shaft_len = r_globe * 0.36
    join_half = r_head * 0.92

    # Base of head (wide end of shaft) — outward from globe along u.
    jx = tip_x + shaft_len * ux
    jy = tip_y + shaft_len * uy
    hc_x = jx + r_head * 0.95 * ux
    hc_y = jy + r_head * 0.95 * uy

    # Perpendicular for shaft width at join.
    px, py = -uy, ux
    base_w = join_half * 1.05

    shaft = [
        (tip_x, tip_y),
        (jx + base_w * px, jy + base_w * py),
        (jx - base_w * px, jy - base_w * py),
    ]

    drw.polygon(shaft, fill=PIN_ORANGE, outline=PIN_WHITE, width=8)

    hb = (
        hc_x - r_head,
        hc_y - r_head,
        hc_x + r_head,
        hc_y + r_head,
    )
    drw.ellipse(hb, fill=PIN_ORANGE)

    hl = r_head * 0.42
    drw.ellipse(
        (
            hc_x - hl * 0.15 - hl * 0.55,
            hc_y - hl * 1.05 - hl * 0.55,
            hc_x - hl * 0.15 + hl * 0.55,
            hc_y - hl * 1.05 + hl * 0.55,
        ),
        fill=PIN_HIGHLIGHT,
    )
    drw.ellipse(hb, outline=PIN_WHITE, width=9)

    hole_r = r_head * 0.36
    hox = hc_x - r_head * 0.08 * ux
    hoy = hc_y - r_head * 0.22 * uy
    drw.ellipse(
        (
            hox - hole_r,
            hoy - hole_r,
            hox + hole_r,
            hoy + hole_r,
        ),
        fill=PIN_HOLE,
        outline=PIN_WHITE,
        width=4,
    )


def embed_center(rgb: np.ndarray, scale: float) -> tuple[np.ndarray, tuple[int, int, int, int]]:
    im = Image.fromarray(rgb.astype(np.uint8), mode="RGB")
    nw = max(1, int(round(CANVAS * scale)))
    nh = max(1, int(round(CANVAS * scale)))
    small = im.resize((nw, nh), Image.Resampling.LANCZOS)
    bg = np.zeros((CANVAS, CANVAS, 3), dtype=np.uint8)
    bg[:, :] = MIDNIGHT.astype(np.uint8)
    ox = (CANVAS - nw) // 2
    oy = (CANVAS - nh) // 2
    bg[oy : oy + nh, ox : ox + nw] = np.array(small)
    return bg, (ox, oy, nw, nh)


def main() -> None:
    if not GEOJSON.is_file():
        raise SystemExit(f"Missing {GEOJSON}")

    project = make_project_fn(GCX, GCY, R_GLOBE)
    land_mask_im = build_land_mask(project)
    land_m = np.array(land_mask_im, dtype=np.float32) / 255.0

    yy, xx = np.ogrid[:CANVAS, :CANVAS]
    d = np.sqrt((xx.astype(np.float32) - GCX) ** 2 + (yy.astype(np.float32) - GCY) ** 2)
    disk = d <= R_GLOBE
    land_m = np.clip(land_m * disk.astype(np.float32), 0.0, 1.0)
    # Solid fills only — no Gaussian blur or gradient coast.
    is_land = land_m >= 0.5

    rgb = np.broadcast_to(MIDNIGHT, (CANVAS, CANVAS, 3)).copy()
    ocean = np.broadcast_to(OCEAN_RGB, (CANVAS, CANVAS, 3))
    land = np.broadcast_to(LAND_RGB, (CANVAS, CANVAS, 3))
    rgb[disk & is_land] = land[disk & is_land]
    rgb[disk & ~is_land] = ocean[disk & ~is_land]

    rgb_u8 = np.clip(rgb, 0, 255).astype(np.uint8)

    im = Image.fromarray(rgb_u8, mode="RGB")
    draw_map_pin(im, GCX, GCY, R_GLOBE, PIN_ANGLE_DEG)
    rgb_out = np.array(im, dtype=np.uint8)

    rgb_out, _bounds = embed_center(rgb_out, SAFE_SCALE)

    Image.fromarray(rgb_out, "RGB").save(IOS_OUT)
    print(f"Wrote {IOS_OUT.relative_to(ROOT)}")

    alpha = np.full((CANVAS, CANVAS), 255, dtype=np.uint8)
    rgba = np.dstack([rgb_out, alpha])
    Image.fromarray(rgba, "RGBA").save(FG_OUT)
    print(f"Wrote {FG_OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
