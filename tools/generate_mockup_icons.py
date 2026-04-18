#!/usr/bin/env python3
"""Generate Kugla icon + splash assets matching the teal mockup."""

from __future__ import annotations
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

ROOT     = Path(__file__).resolve().parents[1]
ICON_OUT = ROOT / "assets" / "icon" / "kugla_app_icon_ios.png"
FG_OUT   = ROOT / "assets" / "icon" / "kugla_app_icon_foreground.png"
SPLASH   = ROOT / "assets" / "splash" / "splash.png"
SPLASH_H = ROOT / "assets" / "splash" / "splash_hdpi.png"

# ── Palette ───────────────────────────────────────────────────────────────────
TEAL_LIGHT  = np.array([72,  212, 232], dtype=np.float32)  # #48D4E8
TEAL_DARK   = np.array([22,  130, 162], dtype=np.float32)  # #1682A2
BG_INNER    = np.array([90,  220, 240], dtype=np.float32)  # #5ADCF0 — centre highlight
BG_OUTER    = np.array([18,  110, 145], dtype=np.float32)  # #126E91 — edge shadow

OCEAN_LIGHT = np.array([65,  150, 220], dtype=np.float32)  # #4196DC
OCEAN_DARK  = np.array([30,   90, 165], dtype=np.float32)  # #1E5AA5

LAND        = (78,  185, 100)   # #4EB964
LAND_SHADE  = (52,  150,  72)   # #349648
GLOBE_LINE  = (20,   65, 105)   # #144169

PIN_TOP     = (255, 200,  50)   # #FFC832
PIN_MID     = (245, 155,  18)   # #F59B12
PIN_EDGE    = (200, 105,   5)   # #C86905
PIN_DOT     = (28,   55,  88)   # #1C3758
WHITE       = (255, 255, 255)
WHITE_A     = (255, 255, 255, 200)


# ── Numpy smooth gradients ────────────────────────────────────────────────────

def smooth_radial_gradient(
    size: int,
    cx: float, cy: float, r: float,
    c_inner: np.ndarray, c_outer: np.ndarray,
) -> Image.Image:
    """RGBA image: smooth radial gradient inside circle, transparent outside."""
    ys, xs = np.mgrid[0:size, 0:size]
    dist = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2)
    t = np.clip(dist / r, 0.0, 1.0)          # 0=centre, 1=edge

    rgb = (c_inner[None, None] * (1 - t[:, :, None]) +
           c_outer[None, None] * t[:, :, None]).clip(0, 255).astype(np.uint8)
    alpha = (dist <= r).astype(np.uint8) * 255

    rgba = np.dstack([rgb, alpha])
    return Image.fromarray(rgba, "RGBA")


def smooth_sphere_gradient(
    size: int,
    cx: float, cy: float, r: float,
    c_top: np.ndarray, c_bot: np.ndarray,
) -> Image.Image:
    """RGBA sphere with vertical gradient."""
    ys, xs = np.mgrid[0:size, 0:size]
    dist = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2)
    inside = dist <= r

    t = np.where(inside, np.clip((ys - (cy - r)) / (2 * r), 0.0, 1.0), 0.0)
    rgb = (c_top[None, None] * (1 - t[:, :, None]) +
           c_bot[None, None] * t[:, :, None]).clip(0, 255).astype(np.uint8)
    alpha = inside.astype(np.uint8) * 255

    rgba = np.dstack([rgb, alpha])
    return Image.fromarray(rgba, "RGBA")


def linear_gradient_image(w: int, h: int, c1: tuple, c2: tuple) -> Image.Image:
    arr = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        t = y / max(h - 1, 1)
        arr[y] = [int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3)]
    return Image.fromarray(arr, "RGB")


# ── Orthographic projection ───────────────────────────────────────────────────

def ortho(lon_deg, lat_deg, clon, clat, r, cx, cy):
    lon  = math.radians(lon_deg - clon)
    lat  = math.radians(lat_deg)
    clat = math.radians(clat)
    cos_c = math.sin(clat)*math.sin(lat) + math.cos(clat)*math.cos(lat)*math.cos(lon)
    if cos_c < 0:
        return None
    x =  r * math.cos(lat) * math.sin(lon)
    y = -r * (math.cos(clat)*math.sin(lat) - math.sin(clat)*math.cos(lat)*math.cos(lon))
    return (cx + x, cy + y)


def project(coords, clon, clat, r, cx, cy):
    pts = [ortho(lo, la, clon, clat, r, cx, cy) for lo, la in coords]
    return [p for p in pts if p is not None]


# ── Continent data (lon, lat) — Africa-centred view ──────────────────────────
AFRICA = [
    (-17,15),(-17,10),(-15,5),(-10,5),(-5,5),(0,4),(5,4),(8,2),(10,-1),
    (15,-5),(22,-5),(30,-4),(34,-3),(37,2),(40,8),(43,14),(50,12),
    (44,20),(38,30),(32,31),(27,37),(20,37),(15,37),(10,36),(5,37),
    (-2,35),(-6,37),(-10,36),(-14,34),(-17,28),(-17,20),(-17,15),
]
EUROPE = [
    (-10,37),(-5,36),(0,37),(5,43),(8,44),(15,45),(20,44),(26,42),
    (29,41),(35,42),(35,47),(28,53),(18,55),(14,57),(5,58),(0,55),
    (-5,50),(-8,42),(-10,37),
]
S_AMERICA = [
    (-35,5),(-50,0),(-60,-5),(-70,-10),(-75,-20),(-70,-35),
    (-65,-45),(-55,-55),(-50,-52),(-45,-45),(-40,-35),
    (-35,-22),(-35,-10),(-35,5),
]
N_AMERICA = [
    (-65,18),(-80,15),(-85,22),(-90,28),(-100,35),(-95,40),
    (-82,45),(-75,45),(-70,46),(-65,44),(-60,47),(-55,50),
    (-60,55),(-65,58),(-70,60),(-65,65),(-52,60),(-55,50),
    (-70,45),(-75,35),(-75,25),(-70,18),(-65,18),
]


# ── Globe ─────────────────────────────────────────────────────────────────────

def draw_globe(canvas: Image.Image, cx, cy, r, clon=18.0, clat=3.0):
    # Smooth ocean sphere
    ocean = smooth_sphere_gradient(
        canvas.width, cx, cy, r, OCEAN_LIGHT, OCEAN_DARK
    )
    canvas.alpha_composite(ocean)

    draw = ImageDraw.Draw(canvas)

    # Continents
    for poly in [AFRICA, EUROPE, S_AMERICA, N_AMERICA]:
        pts = project(poly, clon, clat, r, cx, cy)
        if len(pts) >= 3:
            draw.polygon(pts, fill=LAND)
            draw.polygon(pts, outline=LAND_SHADE, width=max(1, int(r * 0.010)))

    # Globe outline
    lw = max(2, int(r * 0.030))
    draw.ellipse((cx-r, cy-r, cx+r, cy+r), outline=GLOBE_LINE, width=lw)

    # Atmosphere highlight (upper-left arc, semi-transparent)
    hi_r = r * 0.90
    hi_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    hi_draw  = ImageDraw.Draw(hi_layer)
    hi_draw.arc(
        (cx-hi_r, cy-hi_r, cx+hi_r, cy+hi_r),
        start=205, end=325,
        fill=(255, 255, 255, 60),
        width=max(2, int(r * 0.022)),
    )
    canvas.alpha_composite(hi_layer)


# ── Pin ───────────────────────────────────────────────────────────────────────

def draw_pin(canvas: Image.Image, tip_x, tip_y, pin_h):
    draw = ImageDraw.Draw(canvas)
    hr   = pin_h * 0.36           # head radius
    hcx  = tip_x
    hcy  = tip_y - pin_h + hr

    def teardrop(cx, cy, head_r, tx, ty):
        pts = [(cx + head_r * math.cos(math.radians(a)),
                cy - head_r * math.sin(math.radians(a)))
               for a in range(0, 181)]
        pts.append((tx, ty))
        return pts

    out_r = hr + pin_h * 0.065
    draw.polygon(teardrop(hcx, hcy, out_r, tip_x, tip_y + pin_h * 0.045), fill=WHITE)
    draw.polygon(teardrop(hcx, hcy, hr,    tip_x, tip_y),                  fill=PIN_MID)

    # Top-half highlight
    hi_pts = teardrop(hcx, hcy - hr * 0.10, hr * 0.72, hcx, hcy + hr * 0.48)
    draw.polygon(hi_pts, fill=PIN_TOP)
    draw.polygon(teardrop(hcx, hcy, hr, tip_x, tip_y), outline=PIN_EDGE,
                 width=max(1, int(pin_h * 0.022)))

    # Centre dot
    dr = hr * 0.33
    draw.ellipse((hcx-dr, hcy-dr, hcx+dr, hcy+dr), fill=PIN_DOT)


# ── Icon (1024×1024) ──────────────────────────────────────────────────────────

def make_icon(size: int = 1024) -> Image.Image:
    cx = cy = size / 2.0
    bg_r    = size / 2.0
    globe_r = size * 0.295

    # 1. Smooth radial teal background
    icon = smooth_radial_gradient(size, cx, cy, bg_r, BG_INNER, BG_OUTER)

    # 2. Subtle concentric ring hints (very faint, like the mockup)
    ring_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring_layer)
    for i in range(1, 7):
        ri = bg_r * (0.88 - i * 0.10)
        if ri < 10:
            break
        alpha = max(0, 35 - i * 4)
        rd.ellipse((cx-ri, cy-ri, cx+ri, cy+ri),
                   outline=(255, 255, 255, alpha), width=max(1, int(bg_r * 0.012)))
    icon.alpha_composite(ring_layer)

    # 3. Globe — offset slightly down to make room for pin above
    gcx = cx
    gcy = cy + size * 0.055
    draw_globe(icon, gcx, gcy, globe_r)

    # 4. Pin — tip anchored on globe surface, upper portion
    pin_h   = size * 0.30
    pin_x   = gcx + globe_r * 0.16
    pin_tip = gcy - globe_r * 0.55
    draw_pin(icon, pin_x, pin_tip, pin_h)

    # 5. Circular mask
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size, size), fill=255)
    icon.putalpha(mask)

    return icon


def make_ios_icon(size: int = 1024) -> Image.Image:
    """Full-bleed square version (for flutter_launcher_icons)."""
    c1 = tuple(TEAL_LIGHT.astype(int).tolist())
    c2 = tuple(TEAL_DARK.astype(int).tolist())
    bg = linear_gradient_image(size, size, c1, c2).convert("RGBA")
    ic = make_icon(size)
    bg.alpha_composite(ic)
    return bg.convert("RGB")


# ── Splash screen ─────────────────────────────────────────────────────────────

def make_splash(w: int = 1080, h: int = 1920) -> Image.Image:
    c1 = tuple(TEAL_LIGHT.astype(int).tolist())
    c2 = tuple(TEAL_DARK.astype(int).tolist())
    img = linear_gradient_image(w, h, c1, c2).convert("RGBA")

    # Logo (circular icon, no square background)
    logo_size = int(min(w, h) * 0.38)
    logo_rgba = make_icon(logo_size)

    lx = (w - logo_size) // 2
    ly = int(h * 0.28) - logo_size // 2
    img.alpha_composite(logo_rgba, (lx, ly))

    draw = ImageDraw.Draw(img)

    try:
        from PIL import ImageFont
        font_title = ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            int(h * 0.072),
        )
        font_sub = ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            int(h * 0.030),
        )
    except Exception:
        from PIL import ImageFont
        font_title = ImageFont.load_default()
        font_sub   = font_title

    title_y = ly + logo_size + int(h * 0.038)
    bb = draw.textbbox((0, 0), "KUGLA", font=font_title)
    draw.text(((w - (bb[2]-bb[0])) // 2, title_y), "KUGLA",
              fill=WHITE, font=font_title)

    sub_y = title_y + (bb[3]-bb[1]) + int(h * 0.014)
    bb2 = draw.textbbox((0, 0), "Explore the World", font=font_sub)
    draw.text(((w - (bb2[2]-bb2[0])) // 2, sub_y), "Explore the World",
              fill=(*WHITE, 200), font=font_sub)

    return img.convert("RGB")


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    print("Generating icon assets…")
    (ROOT / "assets" / "icon").mkdir(parents=True, exist_ok=True)
    (ROOT / "assets" / "splash").mkdir(parents=True, exist_ok=True)

    ios = make_ios_icon(1024)
    ios.save(ICON_OUT)
    print(f"  ✓ {ICON_OUT.relative_to(ROOT)}")

    fg = make_icon(1024)
    fg.save(FG_OUT)
    print(f"  ✓ {FG_OUT.relative_to(ROOT)}")

    sp = make_splash(1080, 1920)
    sp.save(SPLASH)
    print(f"  ✓ {SPLASH.relative_to(ROOT)}")

    sh = make_splash(720, 1280)
    sh.save(SPLASH_H)
    print(f"  ✓ {SPLASH_H.relative_to(ROOT)}")

    print("\nDone. Run:  dart run flutter_launcher_icons")


if __name__ == "__main__":
    main()
