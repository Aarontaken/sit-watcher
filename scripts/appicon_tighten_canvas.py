#!/usr/bin/env python3
"""
Tighten SitWatcher App icons: trim outer transparency, shave a bit more from each edge,
then scale content proportionally up to fill 1024² (contain, centered, transparent gutters if needed).

Run after scripts/make_appicon_transparent_bg.py (expects RGBA AppIcon PNGs).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image


def tight_alpha_bbox(im: Image.Image, alpha_floor: int) -> tuple[int, int, int, int] | None:
    """BBox of pixels with alpha > alpha_floor."""
    a = im.split()[3].point(lambda v: 255 if v > alpha_floor else 0)
    return a.getbbox()


def shave_bbox(
    bbox: tuple[int, int, int, int],
    inset_each_side_ratio: float,
    img_w: int,
    img_h: int,
) -> tuple[int, int, int, int]:
    left, upper, right, lower = bbox
    bw = right - left
    bh = lower - upper
    dx = int(bw * inset_each_side_ratio)
    dy = int(bh * inset_each_side_ratio)
    dx = max(dx, 0)
    dy = max(dy, 0)
    left += dx
    right -= dx
    upper += dy
    lower -= dy
    left = max(0, left)
    upper = max(0, upper)
    right = min(img_w, right)
    lower = min(img_h, lower)
    if right <= left or lower <= upper:
        return bbox
    return left, upper, right, lower


def paste_cover_square(src_rgba: Image.Image, side: int) -> Image.Image:
    """Uniform scale up so shorter dimension fills `side`; center-crop to square `side`."""
    cw, ch = src_rgba.size
    scale = max(side / cw, side / ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = src_rgba.resize((nw, nh), Image.Resampling.LANCZOS)
    x0 = (nw - side) // 2
    y0 = (nh - side) // 2
    cropped = resized.crop((x0, y0, x0 + side, y0 + side))
    return cropped


def paste_contain_square(src_rgba: Image.Image, side: int) -> Image.Image:
    """Uniform scale down/up so image fits inside side²; centered on transparent canvas."""
    cw, ch = src_rgba.size
    scale = min(side / cw, side / ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = src_rgba.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    ox = (side - nw) // 2
    oy = (side - nh) // 2
    canvas.alpha_composite(resized, (ox, oy))
    return canvas


def main() -> int:
    parser = argparse.ArgumentParser(description="Crop tighter App Icon content and upscale into square.")
    parser.add_argument(
        "--shave",
        type=float,
        default=0.04,
        metavar="RATIO",
        help="Fraction of bbox width/height to remove from EACH edge (default 0.04 ≈ 4%% each side)",
    )
    parser.add_argument(
        "--mode",
        choices=("cover", "contain"),
        default="cover",
        help="cover = maximize pixels (center crop); contain = fit inside square with possible gutters",
    )
    parser.add_argument("--alpha-floor", type=int, default=12, help="Alpha threshold for content bbox")
    args = parser.parse_args()

    repo = Path(__file__).resolve().parents[1]
    iconset = repo / "SitWatcher/Resources/Assets.xcassets/AppIcon.appiconset"
    master_p = iconset / "appicon_512@2x.png"
    if not master_p.is_file():
        print(f"missing {master_p}", file=sys.stderr)
        return 1

    img = Image.open(master_p).convert("RGBA")
    w, h = img.size
    bbox = tight_alpha_bbox(img, args.alpha_floor)
    if bbox is None:
        print("No opaque pixels found.", file=sys.stderr)
        return 1

    bbox = shave_bbox(bbox, args.shave, w, h)
    cropped = img.crop(bbox)

    side = 1024
    if args.mode == "cover":
        out = paste_cover_square(cropped, side)
    else:
        out = paste_contain_square(cropped, side)

    out.save(master_p)

    targets = [
        (iconset / "appicon_512.png", 512),
        (iconset / "appicon_256@2x.png", 512),
        (iconset / "appicon_256.png", 256),
        (iconset / "appicon_128@2x.png", 256),
        (iconset / "appicon_128.png", 128),
    ]
    src = Image.open(master_p).convert("RGBA")
    for path, s in targets:
        src.resize((s, s), Image.Resampling.LANCZOS).save(path)

    print(f"Tightened icons → {master_p} (shave_each_edge={args.shave}, mode={args.mode})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
