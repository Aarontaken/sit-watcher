#!/usr/bin/env bash
# Regenerate screenshots/floating-reminder-demo-en.gif (English UI) from a local recording.
# Place 弹窗录屏.mov in screenshots/ then from repo root:
#   bash scripts/regenerate_floating_demo_gif_en.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/screenshots"
SRC="弹窗录屏.mov"
DST="floating-reminder-demo-en.gif"
if [[ ! -f "$SRC" ]]; then
  echo "Missing $SRC — add your English UI recording under screenshots/ first." >&2
  exit 1
fi
ffmpeg -y -ss 0 -i "$SRC" -t 1 \
  -filter_complex "[0:v]fps=10,scale=560:-2:flags=lanczos,format=gbrp,split[a][b];[a]palettegen=reserve_transparent=0:stats_mode=diff:max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:new=1" \
  -loop 0 "$DST"
echo "Wrote screenshots/$DST"
