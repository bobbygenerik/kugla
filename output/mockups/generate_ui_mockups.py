from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


OUT_DIR = Path("/home/bobbygenerik/kugla/output/mockups")
MAP_BG_PATH = Path("/home/bobbygenerik/Downloads/Gemini_Generated_Image_gtdax0gtdax0gtda~2.png")

PHONE_W = 430
PHONE_H = 932
CANVAS_W = PHONE_W * 3 + 220
CANVAS_H = PHONE_H + 180

DEEP_SPACE = "#0B0D12"
MIDNIGHT = "#12161D"
PANEL = "#1A1F27"
PANEL_RAISED = "#212833"
TEXT = "#F4F7FB"
TEXT_MUTED = "#9DA7B6"
STROKE = "#2D3644"
STEEL = "#7F8EA3"
ICE = "#9FC3FF"
ICE_BRIGHT = "#D9E8FF"
SKY = "#6EA8FE"
SLATE = "#5C6776"
SUCCESS = "#83B7A4"
ROSE = "#B48AA0"
OCEAN = "#3E7CBF"
JADE = "#5FAF98"
TERRACOTTA = "#C7775A"
SAFFRON = "#D7A55A"
INDIGO = "#6D78B8"
PEARL = "#C7CEDA"
BRASS = "#B8924E"
PARCHMENT = "#D8C6A5"
GRAPHITE = "#20252D"
INK = "#0F141B"
FOG = "#A9B5C6"


def rgba(hex_color, alpha=255):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def font(size, bold=False):
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
        if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf"
        if bold
        else "/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


TITLE = font(34, bold=True)
HERO = font(34, bold=True)
SUBTITLE = font(19)
LABEL = font(16, bold=True)
BODY = font(18)
SMALL = font(15)
BIG_NUMBER = font(38, bold=True)
CHIP = font(16, bold=True)


def vertical_gradient(size, top_color, bottom_color):
    w, h = size
    base = Image.new("RGBA", size, rgba(top_color))
    draw = ImageDraw.Draw(base)
    top = rgba(top_color)
    bottom = rgba(bottom_color)
    for y in range(h):
        t = y / max(1, h - 1)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(4))
        draw.line((0, y, w, y), fill=color)
    return base


def vertical_gradient_alpha(size, top_color, bottom_color, top_alpha, bottom_alpha):
    w, h = size
    base = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(base)
    top = rgba(top_color, top_alpha)
    bottom = rgba(bottom_color, bottom_alpha)
    for y in range(h):
        t = y / max(1, h - 1)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(4))
        draw.line((0, y, w, y), fill=color)
    return base


def fit_cover(image, size, align_x=0.5, align_y=0.5):
    src_w, src_h = image.size
    dst_w, dst_h = size
    scale = max(dst_w / src_w, dst_h / src_h)
    resized = image.resize((int(src_w * scale), int(src_h * scale)))
    left = max(0, int((resized.width - dst_w) * align_x))
    top = max(0, int((resized.height - dst_h) * align_y))
    return resized.crop((left, top, left + dst_w, top + dst_h))


def color_overlay(size, color, alpha):
    return Image.new("RGBA", size, rgba(color, alpha))


def draw_dashed_arc(draw, box, start, end, color, width=2, dash=8, gap=7):
    angle = start
    while angle < end:
        seg_end = min(angle + dash, end)
        draw.arc(box, start=angle, end=seg_end, fill=rgba(color, 90), width=width)
        angle += dash + gap


def draw_globe_overlay(base):
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    globe_box = (34, 124, 392, 482)
    draw.ellipse(globe_box, outline=rgba(ICE, 46), width=2)
    for inset in (28, 56, 84):
        draw.arc(
            (34 + inset, 124, 392 - inset, 482),
            start=70,
            end=290,
            fill=rgba(PEARL, 28),
            width=1,
        )
        draw.arc(
            (34, 124 + inset, 392, 482 - inset),
            start=8,
            end=172,
            fill=rgba(PEARL, 24),
            width=1,
        )
    draw_dashed_arc(draw, (62, 152, 364, 454), 210, 330, JADE, width=2)
    draw_dashed_arc(draw, (86, 170, 340, 430), 15, 128, TERRACOTTA, width=2)
    draw_dashed_arc(draw, (80, 188, 350, 448), 150, 222, SAFFRON, width=2)
    for x, y, color in (
        (118, 258, ICE),
        (278, 220, JADE),
        (316, 326, TERRACOTTA),
        (170, 378, SAFFRON),
    ):
        draw.ellipse((x - 5, y - 5, x + 5, y + 5), fill=rgba(color, 180))
        draw.ellipse((x - 10, y - 10, x + 10, y + 10), outline=rgba(color, 84), width=2)
    return overlay.filter(ImageFilter.GaussianBlur(0.5))


def draw_topographic_lines(size):
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    w, h = size
    contours = [
        [
            (int(w * 0.06), int(h * 0.58)),
            (int(w * 0.22), int(h * 0.54)),
            (int(w * 0.40), int(h * 0.56)),
            (int(w * 0.60), int(h * 0.52)),
            (int(w * 0.88), int(h * 0.56)),
        ],
        [
            (int(w * 0.04), int(h * 0.64)),
            (int(w * 0.24), int(h * 0.60)),
            (int(w * 0.44), int(h * 0.62)),
            (int(w * 0.66), int(h * 0.58)),
            (int(w * 0.92), int(h * 0.63)),
        ],
        [
            (int(w * 0.06), int(h * 0.71)),
            (int(w * 0.28), int(h * 0.67)),
            (int(w * 0.48), int(h * 0.69)),
            (int(w * 0.68), int(h * 0.65)),
            (int(w * 0.90), int(h * 0.70)),
        ],
        [
            (int(w * 0.09), int(h * 0.77)),
            (int(w * 0.31), int(h * 0.74)),
            (int(w * 0.50), int(h * 0.76)),
            (int(w * 0.70), int(h * 0.73)),
            (int(w * 0.89), int(h * 0.76)),
        ],
    ]
    for index, points in enumerate(contours):
        color = PEARL if index % 2 == 0 else STEEL
        draw.line(points, fill=rgba(color, 34), width=2, joint="curve")
    return overlay.filter(ImageFilter.GaussianBlur(0.6))


def draw_compass_rose(size, center=(334, 112), radius=34):
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    cx, cy = center
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=rgba(PEARL, 46), width=1)
    for dx, dy, color in (
        (0, -radius + 6, ICE),
        (radius - 8, 0, JADE),
        (0, radius - 8, TERRACOTTA),
        (-radius + 8, 0, BRASS),
    ):
        draw.line((cx, cy, cx + dx, cy + dy), fill=rgba(color, 120), width=2)
    draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=rgba(ICE_BRIGHT, 180))
    return overlay.filter(ImageFilter.GaussianBlur(0.3))


def draw_antique_map_texture(size):
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    w, h = size

    coastlines = [
        [
            (int(w * 0.06), int(h * 0.23)),
            (int(w * 0.18), int(h * 0.20)),
            (int(w * 0.28), int(h * 0.22)),
            (int(w * 0.36), int(h * 0.20)),
            (int(w * 0.46), int(h * 0.23)),
            (int(w * 0.56), int(h * 0.22)),
        ],
        [
            (int(w * 0.58), int(h * 0.28)),
            (int(w * 0.68), int(h * 0.25)),
            (int(w * 0.78), int(h * 0.27)),
            (int(w * 0.86), int(h * 0.24)),
            (int(w * 0.94), int(h * 0.27)),
        ],
        [
            (int(w * 0.10), int(h * 0.76)),
            (int(w * 0.22), int(h * 0.72)),
            (int(w * 0.34), int(h * 0.74)),
            (int(w * 0.46), int(h * 0.71)),
            (int(w * 0.58), int(h * 0.74)),
            (int(w * 0.70), int(h * 0.71)),
            (int(w * 0.84), int(h * 0.75)),
        ],
    ]
    for line in coastlines:
        draw.line(line, fill=rgba(FOG, 30), width=2, joint="curve")
        shadow_line = [(x, y + 6) for x, y in line]
        draw.line(shadow_line, fill=rgba(STEEL, 16), width=1, joint="curve")

    for y in range(int(h * 0.15), int(h * 0.90), max(48, int(h * 0.10))):
        draw.arc((int(w * 0.07), y - int(h * 0.05), int(w * 0.93), y + int(h * 0.05)), 190, 350, fill=rgba(FOG, 18), width=1)
    for x in range(int(w * 0.08), int(w * 0.92), max(48, int(w * 0.16))):
        draw.arc((x - int(w * 0.06), int(h * 0.12), x + int(w * 0.06), int(h * 0.88)), 82, 278, fill=rgba(FOG, 16), width=1)

    route_sets = [
        ((int(w * 0.14), int(h * 0.16), int(w * 0.84), int(h * 0.46)), 208, 328, STEEL),
        ((int(w * 0.22), int(h * 0.19), int(w * 0.76), int(h * 0.43)), 16, 124, JADE),
        ((int(w * 0.14), int(h * 0.65), int(w * 0.86), int(h * 0.92)), 198, 318, OCEAN),
    ]
    for box, start, end, color in route_sets:
        draw_dashed_arc(draw, box, start, end, color, width=2)

    markers = [
        (int(w * 0.30), int(h * 0.26), FOG),
        (int(w * 0.66), int(h * 0.32), JADE),
        (int(w * 0.49), int(h * 0.80), OCEAN),
        (int(w * 0.75), int(h * 0.72), OCEAN),
    ]
    for x, y, color in markers:
        draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=rgba(color, 170))
        draw.ellipse((x - 11, y - 11, x + 11, y + 11), outline=rgba(color, 52), width=1)

    return overlay.filter(ImageFilter.GaussianBlur(0.4))


def draw_edge_vignette(size):
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    w, h = size
    for inset, alpha in ((0, 54), (22, 38), (48, 24)):
        draw.rounded_rectangle(
            (inset, inset, w - inset, h - inset),
            radius=64,
            outline=(0, 0, 0, alpha),
            width=28 if inset == 0 else 18,
        )
    return overlay.filter(ImageFilter.GaussianBlur(12))


def build_map_background(size, align_x=0.5, align_y=0.5, tint_alpha=20):
    source = Image.open(MAP_BG_PATH).convert("RGBA")
    fitted = fit_cover(source, size, align_x=align_x, align_y=align_y)
    fitted = fitted.filter(ImageFilter.GaussianBlur(0.1))
    base = Image.new("RGBA", size, (0, 0, 0, 0))
    base.alpha_composite(fitted)
    base.alpha_composite(color_overlay(size, "#081018", tint_alpha))
    base.alpha_composite(
        vertical_gradient_alpha(size, "#18232E", "#0B1118", 72, 96),
    )
    base.alpha_composite(color_overlay(size, "#13202A", 18))
    return base


def frosted_panel(base, box, tint, outline, radius=28):
    rounded_card(base, box, tint, outline=outline, radius=radius, shadow=True)
    x1, y1, x2, y2 = box
    gloss = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(gloss)
    draw.rounded_rectangle(
        (x1 + 2, y1 + 2, x2 - 2, (y1 + y2) // 2),
        radius=radius,
        fill=rgba("#FFFFFF", 12),
    )
    gloss = gloss.filter(ImageFilter.GaussianBlur(10))
    base.alpha_composite(gloss)


def text_scrim(base, box, radius=28, alpha=150):
    x1, y1, x2, y2 = box
    scrim = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(scrim)
    draw.rounded_rectangle(
        box,
        radius=radius,
        fill=rgba("#0A1016", alpha),
    )
    draw.rounded_rectangle(
        (x1 + 2, y1 + 2, x2 - 2, y1 + int((y2 - y1) * 0.55)),
        radius=radius,
        fill=rgba("#FFFFFF", 10),
    )
    scrim = scrim.filter(ImageFilter.GaussianBlur(12))
    base.alpha_composite(scrim)


def rounded_card(base, box, fill, outline=None, radius=28, shadow=True):
    x1, y1, x2, y2 = box
    if shadow:
        shadow_img = Image.new("RGBA", base.size, (0, 0, 0, 0))
        sdraw = ImageDraw.Draw(shadow_img)
        sdraw.rounded_rectangle(
            (x1, y1 + 10, x2, y2 + 10),
            radius=radius,
            fill=(0, 0, 0, 88),
        )
        shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(18))
        base.alpha_composite(shadow_img)
    draw = ImageDraw.Draw(base)
    draw.rounded_rectangle(
        box,
        radius=radius,
        fill=rgba(fill),
        outline=rgba(outline) if outline else None,
        width=2,
    )


def draw_text(draw, xy, text, font_obj, fill, anchor=None):
    draw.text(xy, text, font=font_obj, fill=rgba(fill), anchor=anchor)


def wrap_text(draw, text, font_obj, max_width):
    words = text.split()
    lines = []
    current = ""
    for word in words:
        trial = word if not current else f"{current} {word}"
        bbox = draw.textbbox((0, 0), trial, font=font_obj)
        if bbox[2] - bbox[0] <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def draw_paragraph(draw, x, y, text, font_obj, fill, max_width, line_gap=8):
    lines = []
    for block in text.split("\n"):
        if not block:
            lines.append("")
            continue
        lines.extend(wrap_text(draw, block, font_obj, max_width))
    line_height = font_obj.size + line_gap
    for index, line in enumerate(lines):
        draw.text((x, y + index * line_height), line, font=font_obj, fill=rgba(fill))
    return y + max(0, len(lines) - 1) * line_height + font_obj.size


def chip(base, x, y, text, accent, fill_alpha=28, w=None):
    draw = ImageDraw.Draw(base)
    if w is None:
        bbox = draw.textbbox((0, 0), text, font=CHIP)
        w = bbox[2] - bbox[0] + 34
    draw.rounded_rectangle(
        (x, y, x + w, y + 38),
        radius=19,
        fill=rgba(accent, fill_alpha),
        outline=rgba(accent, 120),
        width=2,
    )
    draw.text((x + 17, y + 9), text, font=CHIP, fill=rgba(accent))


def progress_bar(draw, box, value, accent, bg=MIDNIGHT):
    x1, y1, x2, y2 = box
    draw.rounded_rectangle(box, radius=(y2 - y1) // 2, fill=rgba(bg))
    width = int((x2 - x1) * value)
    if width > 0:
        draw.rounded_rectangle(
            (x1, y1, x1 + width, y2),
            radius=(y2 - y1) // 2,
            fill=rgba(accent),
        )


def phone_shell(align_x=0.5, align_y=0.5, tint_alpha=20):
    shell = Image.new("RGBA", (PHONE_W, PHONE_H), (0, 0, 0, 0))
    bg = build_map_background(
        (PHONE_W, PHONE_H),
        align_x=align_x,
        align_y=align_y,
        tint_alpha=tint_alpha,
    )
    bg.alpha_composite(color_overlay(bg.size, "#0A1016", 28))
    bg.alpha_composite(draw_edge_vignette(bg.size))
    shell.alpha_composite(bg)
    draw = ImageDraw.Draw(shell)
    draw.rounded_rectangle(
        (0, 0, PHONE_W - 1, PHONE_H - 1),
        radius=56,
        outline=rgba("#394250"),
        width=3,
    )
    draw.rounded_rectangle((138, 18, 292, 42), radius=12, fill=rgba("#05070A"))
    return shell


def screen_home():
    img = phone_shell(align_x=0.18, align_y=0.30, tint_alpha=18)
    draw = ImageDraw.Draw(img)

    text_scrim(img, (30, 98, 338, 396), radius=30, alpha=152)

    draw_text(draw, (42, 82), "Kugla", LABEL, ICE)
    chip(img, 42, 116, "Street View", OCEAN, fill_alpha=18, w=114)
    chip(img, 166, 116, "Vault unlocks", FOG, fill_alpha=16, w=128)
    draw_paragraph(
        draw,
        42,
        164,
        "You see the ground.\nPlace the grid.",
        HERO,
        TEXT,
        260,
        line_gap=4,
    )
    draw_paragraph(
        draw,
        42,
        306,
        "Real Street View rounds: read roads, terrain, and facades, then drop one pin on the map.",
        SUBTITLE,
        TEXT_MUTED,
        250,
        line_gap=5,
    )

    frosted_panel(img, (32, 414, 398, 642), "#1C222C", "#3D495B")
    draw_text(draw, (56, 444), "DAILY PULSE", LABEL, OCEAN)
    draw_text(draw, (56, 484), "Today’s challenge", font(34, bold=True), TEXT)
    draw_paragraph(
        draw,
        56,
        536,
        "5 rounds\n90-second pressure\nStreak bonus active",
        BODY,
        TEXT_MUTED,
        250,
        line_gap=7,
    )
    chip(img, 56, 584, "Play now", OCEAN, w=118)
    chip(img, 184, 584, "3,950 avg", FOG, fill_alpha=16, w=118)

    frosted_panel(img, (32, 670, 206, 856), "#212933", "#384556", radius=24)
    frosted_panel(img, (224, 670, 398, 856), "#212933", "#384556", radius=24)

    draw_text(draw, (54, 700), "World Atlas", LABEL, JADE)
    draw_text(draw, (54, 740), "Explore", font(30, bold=True), TEXT)
    progress_bar(draw, (54, 792, 180, 806), 0.68, JADE)
    draw_paragraph(
        draw,
        54,
        826,
        "Mission trail and regional stats",
        SMALL,
        TEXT_MUTED,
        108,
        line_gap=5,
    )

    draw_text(draw, (246, 700), "Landmark Lock", LABEL, TERRACOTTA)
    draw_text(draw, (246, 740), "Precision", font(30, bold=True), TEXT)
    progress_bar(draw, (246, 792, 372, 806), 0.56, TERRACOTTA)
    draw_paragraph(
        draw,
        246,
        826,
        "Harder reads, tighter scoring",
        SMALL,
        TEXT_MUTED,
        108,
        line_gap=5,
    )

    chip(img, 40, 882, "Home", OCEAN, w=82)
    chip(img, 138, 882, "Play", JADE, fill_alpha=16, w=76)
    chip(img, 229, 882, "Ranks", TERRACOTTA, fill_alpha=16, w=88)
    chip(img, 333, 882, "You", FOG, fill_alpha=16, w=62)
    return img


def screen_game():
    img = phone_shell(align_x=0.48, align_y=0.34, tint_alpha=22)
    draw = ImageDraw.Draw(img)

    frosted_panel(img, (30, 84, 400, 316), "#171D25", "#39475A", radius=30)
    chip(img, 48, 106, "88s", OCEAN, w=66)
    chip(img, 126, 106, "Score 8420", OCEAN, w=126)
    chip(img, 266, 106, "2 / 5", FOG, fill_alpha=18, w=76)
    draw_text(draw, (48, 170), "Find the landmark", font(30, bold=True), TEXT)
    draw_paragraph(
        draw,
        48,
        212,
        "Round 2 of 5  ·  Free roam\nLook for regional architecture, coastal light, and uphill streets.",
        BODY,
        TEXT_MUTED,
        298,
        line_gap=5,
    )

    frosted_panel(img, (32, 350, 398, 648), "#141A22", "#344355", radius=28)
    map_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    mdraw = ImageDraw.Draw(map_layer)
    mdraw.rounded_rectangle(
        (48, 374, 382, 624),
        radius=22,
        fill=rgba("#202631", 210),
        outline=rgba("#425066", 120),
        width=2,
    )
    for points, color in (
        ([(72, 574), (128, 532), (188, 548), (246, 516), (336, 554)], FOG),
        ([(74, 520), (136, 474), (194, 494), (258, 452), (336, 486)], STEEL),
        ([(102, 420), (152, 438), (204, 406), (258, 430), (324, 398)], JADE),
    ):
        mdraw.line(points, fill=rgba(color, 90), width=3, joint="curve")
    for x in range(84, 346, 54):
        mdraw.line((x, 390, x, 610), fill=rgba(FOG, 18), width=1)
    for y in range(404, 612, 48):
        mdraw.line((62, y, 366, y), fill=rgba(FOG, 18), width=1)
    mdraw.ellipse((226, 494, 248, 516), fill=rgba(OCEAN, 220))
    mdraw.ellipse((218, 486, 256, 524), outline=rgba(OCEAN, 130), width=2)
    map_layer = map_layer.filter(ImageFilter.GaussianBlur(0.6))
    img.alpha_composite(map_layer)
    draw_text(draw, (46, 666), "Drop your pin when you’re ready", LABEL, TEXT)

    frosted_panel(img, (32, 716, 398, 868), "#1A2029", "#3A4657", radius=26)
    draw_text(draw, (54, 742), "Guess confidence", LABEL, TEXT_MUTED)
    progress_bar(draw, (54, 784, 376, 800), 0.72, OCEAN)
    draw_paragraph(
        draw,
        54,
        822,
        "Mode color drives score, pressure, and progress while the backdrop hints at routes, regions, and world texture.",
        SMALL,
        TEXT_MUTED,
        312,
        line_gap=5,
    )
    chip(img, 54, 846, "Lock guess", OCEAN, w=120)
    chip(img, 188, 846, "Clear pin", FOG, fill_alpha=18, w=108)
    return img


def screen_leaderboard():
    img = phone_shell(align_x=0.78, align_y=0.32, tint_alpha=18)
    draw = ImageDraw.Draw(img)

    text_scrim(img, (30, 100, 322, 274), radius=30, alpha=146)

    draw_text(draw, (42, 82), "Leaderboard", LABEL, OCEAN)
    draw_text(draw, (42, 122), "Hall of\nNavigators", TITLE, TEXT)
    chip(img, 40, 226, "All", PEARL, fill_alpha=18, w=56)
    chip(img, 106, 226, "Daily", OCEAN, w=74)
    chip(img, 190, 226, "Atlas", JADE, fill_alpha=18, w=74)
    chip(img, 274, 226, "Landmark", TERRACOTTA, fill_alpha=16, w=108)

    rows = [
        ("#1", "Maya", "18,420", OCEAN, 0.94),
        ("#2", "You", "17,980", JADE, 0.89),
        ("#3", "Leo", "17,110", TERRACOTTA, 0.84),
        ("#4", "Ari", "16,220", FOG, 0.76),
    ]
    y = 300
    for rank, name, score, accent, bar in rows:
        frosted_panel(img, (32, y, 398, y + 116), "#1C222C", "#394555", radius=24)
        draw_text(draw, (52, y + 28), rank, BIG_NUMBER, accent)
        draw_text(draw, (122, y + 26), name, font(30, bold=True), TEXT)
        draw_text(draw, (122, y + 62), f"{score} pts", BODY, TEXT_MUTED)
        progress_bar(draw, (280, y + 78, 372, y + 90), bar, accent)
        y += 132

    frosted_panel(img, (32, 840, 398, 900), "#171D26", "#374354", radius=22)
    draw_paragraph(
        draw,
        52,
        858,
        "Personal bests feel more instrument-like when every mode has its own restrained map-inspired accent.",
        SMALL,
        TEXT_MUTED,
        324,
        line_gap=5,
    )
    return img


def add_caption(canvas, x, title, subtitle):
    draw = ImageDraw.Draw(canvas)
    draw_text(draw, (x, 56), title, font(30, bold=True), TEXT)
    draw_paragraph(draw, x, 92, subtitle, SMALL, TEXT_MUTED, 420, line_gap=5)


def save_with_label(board, x, y, screen):
    backing = Image.new("RGBA", board.size, (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(backing)
    bdraw.rounded_rectangle(
        (x - 12, y - 12, x + PHONE_W + 12, y + PHONE_H + 12),
        radius=68,
        fill=rgba("#0E141B", 220),
        outline=rgba("#364252", 140),
        width=2,
    )
    backing = backing.filter(ImageFilter.GaussianBlur(6))
    board.alpha_composite(backing)

    shadow = Image.new("RGBA", board.size, (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        (x + 10, y + 24, x + PHONE_W + 10, y + PHONE_H + 24),
        radius=60,
        fill=(0, 0, 0, 100),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))
    board.alpha_composite(shadow)
    board.alpha_composite(screen, (x, y))


def map_window(base, box, align_x, align_y, alpha=210):
    x1, y1, x2, y2 = box
    window = build_map_background((x2 - x1, y2 - y1), align_x=align_x, align_y=align_y)
    mask = Image.new("L", (x2 - x1, y2 - y1), alpha)
    rgba_window = Image.new("RGBA", (x2 - x1, y2 - y1), (0, 0, 0, 0))
    rgba_window.alpha_composite(window)
    rgba_window.putalpha(mask)
    base.alpha_composite(rgba_window, (x1, y1))


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    home = screen_home()
    game = screen_game()
    leaderboard = screen_leaderboard()

    home.save(OUT_DIR / "mockup-home-industrial.png")
    game.save(OUT_DIR / "mockup-game-industrial.png")
    leaderboard.save(OUT_DIR / "mockup-leaderboard-industrial.png")

    board_source = Image.open(MAP_BG_PATH).convert("RGBA")
    board = fit_cover(board_source, (CANVAS_W, CANVAS_H), align_x=0.50, align_y=0.48)
    board.alpha_composite(color_overlay((CANVAS_W, CANVAS_H), "#081018", 54))
    board.alpha_composite(
        vertical_gradient_alpha(
            (CANVAS_W, CANVAS_H),
            "#1A2733",
            "#0B1016",
            84,
            108,
        ),
    )
    board.alpha_composite(color_overlay((CANVAS_W, CANVAS_H), "#0A1016", 34))
    board.alpha_composite(draw_edge_vignette((CANVAS_W, CANVAS_H)))

    add_caption(
        board,
        64,
        "Kugla UI Direction",
        "Modern atlas / premium travel instrument: cartographic layers, frosted panels, route-blue highlights, and cool metal detail.",
    )

    placements = [
        (54, 146, home, "Home"),
        (502, 146, game, "In-game"),
        (950, 146, leaderboard, "Leaderboard"),
    ]

    for x, y, screen, _ in placements:
        save_with_label(board, x, y, screen)

    draw = ImageDraw.Draw(board)
    for x, _, _, label in placements:
        draw_text(draw, (x, CANVAS_H - 46), label, LABEL, ICE_BRIGHT)

    board.save(OUT_DIR / "mockup-board-industrial.png")


if __name__ == "__main__":
    main()
