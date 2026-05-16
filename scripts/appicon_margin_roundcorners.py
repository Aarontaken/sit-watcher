#!/usr/bin/env python3
"""
Add transparent margin around App Icon content (scale down + center on 1024²),
then strengthen corner rounding by multiplying alpha with a rounded-rectangle mask
fitted to the content bounds.

Run from repo root. Reads/writes AppIcon.appiconset/appicon_512@2x.png and mipmaps.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


def alpha_bbox(im: Image.Image, alpha_floor: int) -> tuple[int, int, int, int] | None:
    a = im.split()[3].point(lambda v: 255 if v > alpha_floor else 0)
    return a.getbbox()


def mipmap_save(master: Image.Image, iconset: Path) -> None:
    master.save(iconset / "appicon_512@2x.png")
    src = master.convert("RGBA")
    targets = [
        (iconset / "appicon_512.png", 512),
        (iconset / "appicon_256@2x.png", 512),
        (iconset / "appicon_256.png", 256),
        (iconset / "appicon_128@2x.png", 256),
        (iconset / "appicon_128.png", 128),
    ]
    for path, side in targets:
        src.resize((side, side), Image.Resampling.LANCZOS).save(path)


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument(
        "--fill",
        type=float,
        default=0.82,
        metavar="F",
        help="Max content width/height as fraction of 1024 before rounding (default 0.82 → ~9%% margin each side)",
    )
    p.add_argument(
        "--radius",
        type=int,
        default=188,
        metavar="PX",
        help="Rounded-rectangle corner radius in pixels at 1024 canvas (clamped to content)",
    )
    p.add_argument("--alpha-floor", type=int, default=12)
    args = p.parse_args()

    repo = Path(__file__).resolve().parents[1]
    iconset = repo / "SitWatcher/Resources/Assets.xcassets/AppIcon.appiconset"
    master_p = iconset / "appicon_512@2x.png"
    if not master_p.is_file():
        print(f"missing {master_p}", file=sys.stderr)
        return 1

    img = Image.open(master_p).convert("RGBA")
    bbox = alpha_bbox(img, args.alpha_floor)
    if bbox is None:
        print("No content.", file=sys.stderr)
        return 1

    cropped = img.crop(bbox)
    cw, ch = cropped.size
    target = max(1, int(round(1024 * args.fill)))
    scale = min(target / cw, target / ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    ox = (1024 - nw) // 2
    oy = (1024 - nh) // 2
    canvas.alpha_composite(resized, (ox, oy))

    ab = alpha_bbox(canvas, args.alpha_floor)
    if ab is None:
        print("Empty canvas after paste.", file=sys.stderr)
        return 1

    left, upper, right, lower = ab
    bw = right - left
    bh = lower - upper
    max_r = min(bw, bh) // 2 - 1
    r = max(1, min(args.radius, max_r))

    mask = Image.new("L", (1024, 1024), 0)
    dr = ImageDraw.Draw(mask)
    dr.rounded_rectangle((left, upper, right - 1, lower - 1), radius=r, fill=255)

    r_, g_, b_, a_ = canvas.split()
    new_a = ImageChops.multiply(a_, mask)
    out = Image.merge("RGBA", (r_, g_, b_, new_a))

    mipmap_save(out, iconset)
    print(
        f"OK margin_fill≈{args.fill}, corner_r={r}px (requested {args.radius}), "
        f"content_bbox={bw}x{bh} → pasted {nw}x{nh} at ({ox},{oy})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
