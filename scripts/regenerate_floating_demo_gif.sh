#!/usr/bin/env bash
# Regenerate screenshots/floating-reminder-demo.gif from a local screen recording.
# Place 弹窗视频.mov in screenshots/ (gitignored) then run from repo root:
#   bash scripts/regenerate_floating_demo_gif.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/screenshots"
SRC="弹窗视频.mov"
DST="floating-reminder-demo.gif"
if [[ ! -f "$SRC" ]]; then
  echo "Missing $SRC — add your recording under screenshots/ first." >&2
  exit 1
fi
ffmpeg -y -ss 0 -i "$SRC" -t 1 \
  -filter_complex "[0:v]fps=10,scale=560:-2:flags=lanczos,format=gbrp,split[a][b];[a]palettegen=reserve_transparent=0:stats_mode=diff:max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:new=1" \
  -loop 0 "$DST"
echo "Wrote screenshots/$DST"
