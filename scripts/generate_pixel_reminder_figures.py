#!/usr/bin/env python3
"""
Generate pixel-art reminder figure frames for SitWatcher.

The frames are drawn on a tiny grid and scaled with nearest-neighbor sampling,
so the in-app character keeps a crisp pixel style at any display scale.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw


CANVAS = 64
OUTPUT = 512
SCALE = OUTPUT // CANVAS


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.lstrip("#")
    return (
        int(hex_color[0:2], 16),
        int(hex_color[2:4], 16),
        int(hex_color[4:6], 16),
        alpha,
    )


@dataclass(frozen=True)
class PixelPalette:
    outline: tuple[int, int, int, int] = rgba("#1D2526")
    hair: tuple[int, int, int, int] = rgba("#263235")
    skin: tuple[int, int, int, int] = rgba("#F4BC8B")
    cheek: tuple[int, int, int, int] = rgba("#EF7E83")
    shirt: tuple[int, int, int, int] = rgba("#37D0B2")
    shirt_shadow: tuple[int, int, int, int] = rgba("#188F88")
    pants: tuple[int, int, int, int] = rgba("#344E64")
    shoe: tuple[int, int, int, int] = rgba("#202A32")
    white: tuple[int, int, int, int] = rgba("#F8FFF9")
    bottle: tuple[int, int, int, int] = rgba("#63B7FF")
    bottle_dark: tuple[int, int, int, int] = rgba("#2F76C7")


PAL = PixelPalette()


def rect(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, fill) -> None:
    draw.rectangle((x, y, x + w - 1, y + h - 1), fill=fill)


def line(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], fill, width: int = 2) -> None:
    draw.line(points, fill=fill, width=width, joint="curve")


def base_canvas() -> Image.Image:
    return Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))


def draw_head(draw: ImageDraw.ImageDraw, x: int, y: int, mood: str = "smile") -> None:
    rect(draw, x - 5, y - 7, 10, 2, PAL.hair)
    rect(draw, x - 6, y - 5, 12, 4, PAL.hair)
    rect(draw, x - 5, y - 3, 10, 9, PAL.skin)
    rect(draw, x - 6, y - 1, 2, 5, PAL.outline)
    rect(draw, x + 4, y - 1, 2, 5, PAL.outline)
    rect(draw, x - 2, y - 1, 1, 1, PAL.outline)
    rect(draw, x + 3, y - 1, 1, 1, PAL.outline)
    rect(draw, x - 4, y + 3, 2, 1, PAL.cheek)
    rect(draw, x + 4, y + 3, 2, 1, PAL.cheek)
    if mood == "o":
        rect(draw, x + 1, y + 4, 2, 2, PAL.outline)
    elif mood == "focus":
        rect(draw, x, y + 4, 4, 1, PAL.outline)
    else:
        rect(draw, x, y + 4, 4, 1, PAL.outline)
        rect(draw, x + 1, y + 5, 2, 1, PAL.outline)


def draw_torso(draw: ImageDraw.ImageDraw, x: int, y: int, lean: int = 0) -> None:
    rect(draw, x - 6 + lean, y, 12, 15, PAL.outline)
    rect(draw, x - 4 + lean, y + 1, 8, 12, PAL.shirt)
    rect(draw, x + 2 + lean, y + 2, 2, 10, PAL.shirt_shadow)


def draw_walk(frame: int) -> Image.Image:
    img = base_canvas()
    draw = ImageDraw.Draw(img)
    x, y = 32, 19 + (frame % 2)
    lean = [-1, 0, 1, 0][frame]
    draw_head(draw, x + lean, y)
    draw_torso(draw, x, y + 7, lean)

    arm_sets = [
        ([(24, 29), (18, 39)], [(40, 29), (45, 36)]),
        ([(25, 30), (21, 38)], [(39, 30), (42, 39)]),
        ([(24, 29), (19, 36)], [(40, 29), (46, 39)]),
        ([(25, 30), (22, 39)], [(39, 30), (43, 37)]),
    ]
    for chain in arm_sets[frame]:
        line(draw, chain, PAL.outline, 4)
        line(draw, chain, PAL.skin, 2)

    leg_sets = [
        ([(29, 41), (22, 51)], [(35, 41), (42, 51)]),
        ([(29, 41), (26, 52)], [(35, 41), (38, 52)]),
        ([(29, 41), (42, 51)], [(35, 41), (22, 51)]),
        ([(29, 41), (27, 52)], [(35, 41), (37, 52)]),
    ]
    for chain in leg_sets[frame]:
        line(draw, chain, PAL.outline, 5)
        line(draw, chain, PAL.pants, 3)
        foot = chain[-1]
        rect(draw, foot[0] - 3, foot[1], 7, 3, PAL.shoe)
    return img


def draw_stretch(frame: int) -> Image.Image:
    img = base_canvas()
    draw = ImageDraw.Draw(img)
    lift = [0, -2, -4, -2][frame]
    x, y = 32, 19 + lift
    draw_head(draw, x, y, "smile")
    draw_torso(draw, x, y + 8, 0)

    arm_sets = [
        [(25, 29), (20, 22), (18, 15), (39, 29), (44, 22), (46, 15)],
        [(25, 28), (22, 18), (24, 11), (39, 28), (42, 18), (40, 11)],
        [(26, 27), (29, 15), (31, 8), (38, 27), (35, 15), (33, 8)],
        [(25, 28), (22, 18), (24, 11), (39, 28), (42, 18), (40, 11)],
    ]
    pts = arm_sets[frame]
    for start in (0, 3):
        chain = pts[start : start + 3]
        line(draw, chain, PAL.outline, 4)
        line(draw, chain, PAL.skin, 2)

    for sx, ex in ((29, 28), (35, 39)):
        line(draw, [(sx, y + 22), (ex, 53)], PAL.outline, 5)
        line(draw, [(sx, y + 22), (ex, 53)], PAL.pants, 3)
        rect(draw, ex - 3, 53, 7, 3, PAL.shoe)
    return img


def draw_jump(frame: int) -> Image.Image:
    img = base_canvas()
    draw = ImageDraw.Draw(img)
    jump = [0, -5, -9, -4][frame]
    x, y = 32, 20 + jump
    draw_head(draw, x, y, "o" if frame == 2 else "smile")
    draw_torso(draw, x, y + 8, 0)

    arms = [
        ([(25, y + 12), (19, y + 18)], [(39, y + 12), (45, y + 18)]),
        ([(25, y + 11), (20, y + 8)], [(39, y + 11), (44, y + 8)]),
        ([(26, y + 10), (22, y + 3)], [(38, y + 10), (42, y + 3)]),
        ([(25, y + 11), (20, y + 9)], [(39, y + 11), (44, y + 9)]),
    ][frame]
    for chain in arms:
        line(draw, chain, PAL.outline, 4)
        line(draw, chain, PAL.skin, 2)

    legs = [
        ([(29, y + 23), (27, 53)], [(35, y + 23), (37, 53)]),
        ([(29, y + 23), (24, 49)], [(35, y + 23), (40, 49)]),
        ([(29, y + 23), (22, 45)], [(35, y + 23), (42, 45)]),
        ([(29, y + 23), (25, 50)], [(35, y + 23), (39, 50)]),
    ][frame]
    for chain in legs:
        line(draw, chain, PAL.outline, 5)
        line(draw, chain, PAL.pants, 3)
        foot = chain[-1]
        rect(draw, foot[0] - 3, foot[1], 7, 3, PAL.shoe)

    if frame in (1, 2, 3):
        rect(draw, 23, 56, 18, 2, rgba("#7CCAB8", 115))
    return img


def draw_hydrate(frame: int) -> Image.Image:
    img = base_canvas()
    draw = ImageDraw.Draw(img)
    x, y = 32, 19
    mood = "focus" if frame in (1, 2) else "smile"
    draw_head(draw, x, y, mood)
    draw_torso(draw, x, y + 8, 0)

    left_arm = [(25, 30), (20, 40)]
    drink_arms = [
        [(39, 30), (45, 38)],
        [(39, 30), (45, 29), (42, 25)],
        [(39, 30), (44, 27), (40, 22)],
        [(39, 30), (45, 38)],
    ]
    line(draw, left_arm, PAL.outline, 4)
    line(draw, left_arm, PAL.skin, 2)
    line(draw, drink_arms[frame], PAL.outline, 4)
    line(draw, drink_arms[frame], PAL.skin, 2)

    bottle_pos = [(44, 37), (41, 24), (38, 20), (44, 37)][frame]
    bx, by = bottle_pos
    rect(draw, bx, by, 5, 10, PAL.outline)
    rect(draw, bx + 1, by + 1, 3, 8, PAL.bottle)
    rect(draw, bx + 3, by + 2, 1, 6, PAL.bottle_dark)
    rect(draw, bx + 1, by - 2, 3, 2, PAL.white)

    for sx, ex in ((29, 27), (35, 38)):
        line(draw, [(sx, 41), (ex, 53)], PAL.outline, 5)
        line(draw, [(sx, 41), (ex, 53)], PAL.pants, 3)
        rect(draw, ex - 3, 53, 7, 3, PAL.shoe)
    return img


FIGURES = {
    "PixelWalk": ("pixel-walk", draw_walk),
    "PixelStretch": ("pixel-stretch", draw_stretch),
    "PixelJump": ("pixel-jump", draw_jump),
    "PixelHydrate": ("pixel-hydrate", draw_hydrate),
}


def upscale(img: Image.Image) -> Image.Image:
    return img.resize((OUTPUT, OUTPUT), Image.Resampling.NEAREST)


def write_contents(path: Path, filename: str) -> None:
    contents = {
        "images": [
            {
                "filename": filename,
                "idiom": "universal",
                "scale": "1x",
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1,
        },
    }
    (path / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")


def save_imageset(asset_root: Path, name: str, filename: str, image: Image.Image) -> None:
    path = asset_root / f"ReminderFigure{name}.imageset"
    path.mkdir(parents=True, exist_ok=True)
    upscale(image).save(path / filename)
    write_contents(path, filename)


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    asset_root = repo / "SitWatcher/Resources/Assets.xcassets"
    if not asset_root.is_dir():
        raise SystemExit(f"Missing asset catalog: {asset_root}")

    for asset_name, (filename_prefix, draw_fn) in FIGURES.items():
        frames = [draw_fn(index) for index in range(4)]
        save_imageset(asset_root, asset_name, f"reminder-figure-{filename_prefix}.png", frames[0])
        for index, frame in enumerate(frames, start=1):
            save_imageset(
                asset_root,
                f"{asset_name}Frame{index}",
                f"reminder-figure-{filename_prefix}-frame-{index}.png",
                frame,
            )

    print(f"Generated {len(FIGURES)} pixel reminder figure sets in {asset_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
