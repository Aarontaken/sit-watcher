#!/usr/bin/env python3
"""
Generate the SitWatcher macOS app icon.

The icon is intentionally drawn as simple vector geometry with Pillow so it can
be regenerated deterministically when the visual language needs small tweaks.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


SIDE = 1024
SCALE = 4


def s(value: float) -> int:
    return int(round(value * SCALE))


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.lstrip("#")
    return (
        int(hex_color[0:2], 16),
        int(hex_color[2:4], 16),
        int(hex_color[4:6], 16),
        alpha,
    )


def vertical_gradient(
    size: tuple[int, int],
    top: tuple[int, int, int, int],
    bottom: tuple[int, int, int, int],
) -> Image.Image:
    w, h = size
    out = Image.new("RGBA", size)
    px = out.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        row = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(4))
        for x in range(w):
            px[x, y] = row
    return out


def linear_gradient(
    size: tuple[int, int],
    start: tuple[float, float],
    end: tuple[float, float],
    colors: tuple[tuple[int, int, int, int], tuple[int, int, int, int]],
) -> Image.Image:
    w, h = size
    out = Image.new("RGBA", size)
    sx, sy = start
    ex, ey = end
    dx = ex - sx
    dy = ey - sy
    length_sq = max(dx * dx + dy * dy, 1.0)
    px = out.load()
    for y in range(h):
        for x in range(w):
            t = ((x - sx) * dx + (y - sy) * dy) / length_sq
            t = min(1.0, max(0.0, t))
            px[x, y] = tuple(int(colors[0][i] * (1 - t) + colors[1][i] * t) for i in range(4))
    return out


def rounded_mask(size: tuple[int, int], rect: tuple[int, int, int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(rect, radius=radius, fill=255)
    return mask


def alpha_composite_masked(dst: Image.Image, src: Image.Image, mask: Image.Image) -> None:
    layer = Image.new("RGBA", dst.size, (0, 0, 0, 0))
    layer.alpha_composite(src)
    r, g, b, a = layer.split()
    layer.putalpha(ImageChops.multiply(a, mask))
    dst.alpha_composite(layer)


def draw_round_line(
    draw: ImageDraw.ImageDraw,
    points: list[tuple[float, float]],
    fill: tuple[int, int, int, int],
    width: float,
) -> None:
    scaled = [(s(x), s(y)) for x, y in points]
    line_width = s(width)
    draw.line(scaled, fill=fill, width=line_width, joint="curve")
    radius = line_width // 2
    for x, y in scaled:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=fill)


def draw_clock_arc(layer: Image.Image) -> None:
    arc = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    mask = Image.new("L", layer.size, 0)
    draw = ImageDraw.Draw(mask)
    bbox = (s(216), s(178), s(808), s(770))
    draw.arc(bbox, start=218, end=36 + 360, fill=255, width=s(38))

    grad = linear_gradient(
        layer.size,
        (s(254), s(696)),
        (s(766), s(230)),
        (rgba("#18DCC8"), rgba("#78E55E")),
    )
    grad.putalpha(mask)

    glow = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    glow_mask = mask.filter(ImageFilter.GaussianBlur(s(14)))
    glow_color = Image.new("RGBA", layer.size, rgba("#16D9BD", 82))
    glow_color.putalpha(glow_mask)
    glow.alpha_composite(glow_color)
    layer.alpha_composite(glow)
    layer.alpha_composite(grad)

    dot = ImageDraw.Draw(layer)
    dot.ellipse((s(750), s(602), s(812), s(664)), fill=rgba("#19C7EA"))


def draw_chair_mark(layer: Image.Image) -> None:
    mark_shadow = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(mark_shadow)
    shadow = rgba("#0A1A24", 58)
    draw_round_line(shadow_draw, [(414, 340), (432, 490), (466, 562), (650, 562)], shadow, 52)
    draw_round_line(shadow_draw, [(468, 566), (434, 708)], shadow, 38)
    draw_round_line(shadow_draw, [(642, 566), (682, 708)], shadow, 38)
    mark_shadow = mark_shadow.filter(ImageFilter.GaussianBlur(s(7)))
    layer.alpha_composite(mark_shadow, (0, s(10)))

    draw = ImageDraw.Draw(layer)
    graphite = rgba("#142229")
    draw_round_line(draw, [(414, 340), (432, 490), (466, 562), (650, 562)], graphite, 52)
    draw_round_line(draw, [(468, 566), (434, 708)], graphite, 38)
    draw_round_line(draw, [(642, 566), (682, 708)], graphite, 38)

    arrow = rgba("#142229", 236)
    draw_round_line(draw, [(610, 442), (610, 336)], arrow, 22)
    draw_round_line(draw, [(560, 382), (610, 332), (660, 382)], arrow, 22)


def build_icon() -> Image.Image:
    canvas = Image.new("RGBA", (s(SIDE), s(SIDE)), (0, 0, 0, 0))
    tile_rect = (s(88), s(88), s(936), s(936))
    tile_radius = s(210)

    shadow_mask = rounded_mask(canvas.size, tile_rect, tile_radius)
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(s(24)))
    shadow = Image.new("RGBA", canvas.size, rgba("#071A1D", 64))
    shadow.putalpha(shadow_mask)
    canvas.alpha_composite(shadow, (0, s(20)))

    tile_mask = rounded_mask(canvas.size, tile_rect, tile_radius)
    tile = vertical_gradient(canvas.size, rgba("#FBFEFA"), rgba("#DDEFE6"))
    alpha_composite_masked(canvas, tile, tile_mask)

    inner_line = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    inner_draw = ImageDraw.Draw(inner_line)
    inner_draw.rounded_rectangle(
        (s(104), s(104), s(920), s(920)),
        radius=s(194),
        outline=rgba("#FFFFFF", 110),
        width=s(3),
    )
    canvas.alpha_composite(inner_line)

    soft_wash = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    wash_draw = ImageDraw.Draw(soft_wash)
    wash_draw.ellipse((s(172), s(136), s(872), s(850)), fill=rgba("#BFEFDD", 52))
    soft_wash = soft_wash.filter(ImageFilter.GaussianBlur(s(54)))
    r, g, b, a = soft_wash.split()
    soft_wash.putalpha(ImageChops.multiply(a, tile_mask))
    canvas.alpha_composite(soft_wash)

    symbol = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw_clock_arc(symbol)
    draw_chair_mark(symbol)
    canvas.alpha_composite(symbol)

    bottom_shade = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shade = ImageDraw.Draw(bottom_shade)
    for i in range(48):
        alpha = int(22 * (1 - i / 48) ** 2)
        shade.rounded_rectangle(
            (s(88 + i * 0.6), s(826 + i), s(936 - i * 0.6), s(936)),
            radius=s(210),
            fill=rgba("#6EA68F", alpha),
        )
    r, g, b, a = bottom_shade.split()
    bottom_shade.putalpha(ImageChops.multiply(a, tile_mask))
    canvas.alpha_composite(bottom_shade)

    return canvas.resize((SIDE, SIDE), Image.Resampling.LANCZOS)


def save_iconset(master: Image.Image, iconset: Path) -> None:
    targets = [
        ("appicon_128.png", 128),
        ("appicon_128@2x.png", 256),
        ("appicon_256.png", 256),
        ("appicon_256@2x.png", 512),
        ("appicon_512.png", 512),
        ("appicon_512@2x.png", 1024),
    ]
    for filename, side in targets:
        master.resize((side, side), Image.Resampling.LANCZOS).save(iconset / filename)


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    iconset = repo / "SitWatcher/Resources/Assets.xcassets/AppIcon.appiconset"
    if not iconset.is_dir():
        raise SystemExit(f"Missing iconset: {iconset}")

    icon = build_icon()
    save_iconset(icon, iconset)
    print(f"Generated SitWatcher app icon set in {iconset}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
