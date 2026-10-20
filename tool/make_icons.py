"""Draws the Cedar Roots mark and writes the launcher icon, splash and in-app logo images.

    python tool/make_icons.py

Everything is drawn at 4x and scaled down for clean edges. The mark stays inside the middle
66% of the canvas so Android's adaptive icon masks (circle, squircle, ...) never cut it.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

S = 1024
SS = 4
GREEN = (15, 61, 46, 255)
CREAM = (244, 239, 224, 255)
GOLD = (217, 178, 111, 255)
WHITE = (255, 255, 255, 255)

OUT = Path(__file__).resolve().parent.parent / "assets" / "icon"


def bezier(p0, p1, p2, steps=40):
    return [
        (
            (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t**2 * p2[0],
            (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t**2 * p2[1],
        )
        for t in (i / steps for i in range(steps + 1))
    ]


def tier(cx, top, bottom, half):
    """A cedar tier: pointed top, sides that bulge out then droop, a shallow notch below."""
    apex = (cx, top)
    right_tip = (cx + half, bottom)
    left_tip = (cx - half, bottom)
    belly = bottom - (bottom - top) * 0.18
    right = bezier(apex, (cx + half * 0.35, top + (bottom - top) * 0.55), right_tip)
    notch = bezier(right_tip, (cx + half * 0.5, belly), (cx, bottom - (bottom - top) * 0.1))
    notch_l = bezier((cx, bottom - (bottom - top) * 0.1), (cx - half * 0.5, belly), left_tip)
    left = bezier(left_tip, (cx - half * 0.35, top + (bottom - top) * 0.55), apex)
    return right + notch[1:] + notch_l[1:] + left[1:]


def root(draw, points, start_width, color):
    n = len(points)
    for i, (x, y) in enumerate(points):
        r = start_width * (1 - 0.82 * i / (n - 1)) / 2
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color)


def mark(tree_color, root_color, scale=1.0):
    """The tree and roots on a transparent canvas, centred, `scale` times the base size."""
    img = Image.new("RGBA", (S * SS, S * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def p(x, y):
        return (512 + (x - 512) * scale) * SS, (512 + (y - 512) * scale) * SS

    def poly(points):
        return [p(x, y) for x, y in points]

    for top, bottom, half in ((185, 365, 105), (275, 485, 160), (385, 610, 220)):
        d.polygon(poly(tier(512, top, bottom, half)), fill=tree_color)
    trunk = [(486, 590), (538, 590), (546, 690), (478, 690)]
    d.polygon(poly(trunk), fill=root_color)

    spreads = [(-215, 800), (-120, 835), (0, 850), (120, 835), (215, 800)]
    for dx, end_y in spreads:
        pts = bezier((512, 680), (512 + dx * 0.15, 760), (512 + dx, end_y), steps=300)
        scaled = [p(x, y) for x, y in pts]
        root(d, scaled, 34 * scale * SS, root_color)
    for dx, end_y in ((-100, 780), (100, 780)):
        pts = bezier((512, 690), (512 + dx * 0.4, 730), (512 + dx, end_y), steps=300)
        root(d, [p(x, y) for x, y in pts], 24 * scale * SS, root_color)

    return img.resize((S, S), Image.LANCZOS)


def on_background(layer, color=GREEN):
    bg = Image.new("RGBA", (S, S), color)
    bg.alpha_composite(layer)
    return bg


def main():
    OUT.mkdir(parents=True, exist_ok=True)

    foreground = mark(CREAM, GOLD)
    foreground.save(OUT / "icon_foreground.png")

    mono = mark(WHITE, WHITE)
    mono.save(OUT / "icon_monochrome.png")

    # Legacy / iOS icon: square, opaque, mark a little larger since there is no mask padding.
    full = on_background(mark(CREAM, GOLD, scale=1.22)).convert("RGB")
    full.save(OUT / "icon_full.png")

    # In-app and splash logo: the mark alone, tight, on transparent.
    tight = mark(CREAM, GOLD, scale=1.0)
    bbox = tight.getbbox()
    tight.crop(bbox).save(OUT / "logo_mark.png")

    # Same mark in the app's text colours for light screens.
    dark = mark((15, 61, 46, 255), (160, 110, 40, 255))
    dark.crop(dark.getbbox()).save(OUT / "logo_mark_dark.png")

    print("wrote", ", ".join(sorted(p.name for p in OUT.glob("icon_*.png"))), "logo_mark*.png")


if __name__ == "__main__":
    main()
