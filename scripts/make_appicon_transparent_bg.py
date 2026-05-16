#!/usr/bin/env python3
"""
Remove uniform outer background from SitWatcher App Icon PNGs via edge flood-fill,
then rescale alpha-preserving mipmaps for AppIcon.appiconset.

Depends only on Pillow (same as many macOS setups via Xcode toolchain python — otherwise pip install Pillow).
"""

from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

from PIL import Image


def _median_rgb(samples: list[tuple[int, int, int]]) -> tuple[float, float, float]:
    rs = sorted(s[0] for s in samples)
    gs = sorted(s[1] for s in samples)
    bs = sorted(s[2] for s in samples)
    mid = len(samples) // 2
    return float(rs[mid]), float(gs[mid]), float(bs[mid])


def _dist_sq(a: tuple[int, int, int], b: tuple[float, float, float]) -> float:
    return float((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2)


def flood_clear_outer_rgba(img: Image.Image, tol: float) -> Image.Image:
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()

    border: list[tuple[int, int, int]] = []
    for x in range(w):
        border.append(px[x, 0][:3])
        border.append(px[x, h - 1][:3])
    for y in range(h):
        border.append(px[0, y][:3])
        border.append(px[w - 1, y][:3])

    bg = _median_rgb(border)
    tol_sq = tol * tol

    def close_at(x: int, y: int) -> bool:
        return _dist_sq(px[x, y][:3], bg) <= tol_sq

    visited = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()

    for x in range(w):
        for y in (0, h - 1):
            if close_at(x, y):
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if close_at(x, y):
                q.append((x, y))

    while q:
        x, y = q.popleft()
        if visited[y][x]:
            continue
        if not close_at(x, y):
            continue
        visited[y][x] = True
        r, g, b, _ = px[x, y]
        px[x, y] = (r, g, b, 0)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx] and close_at(nx, ny):
                q.append((nx, ny))

    return img


def main() -> int:
    tol = float(sys.argv[1]) if len(sys.argv) >= 2 else 42.0

    repo = Path(__file__).resolve().parents[1]
    iconset = repo / "SitWatcher/Resources/Assets.xcassets/AppIcon.appiconset"
    master_p = iconset / "appicon_512@2x.png"
    if not master_p.is_file():
        print(f"missing {master_p}", file=sys.stderr)
        return 1

    base = Image.open(master_p)
    cleared = flood_clear_outer_rgba(base, tol=tol)
    cleared.save(master_p)

    src = Image.open(master_p).convert("RGBA")
    targets = [
        (iconset / "appicon_512.png", 512),
        (iconset / "appicon_256@2x.png", 512),
        (iconset / "appicon_256.png", 256),
        (iconset / "appicon_128@2x.png", 256),
        (iconset / "appicon_128.png", 128),
    ]
    for path, side in targets:
        src.resize((side, side), Image.Resampling.LANCZOS).save(path)

    print(f"Updated AppIcon set, transparent outer flood-fill (median-edge, tol={tol}). {master_p}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
