#!/usr/bin/env bash
# Regenerate light-appearance demo GIFs (first ~1s) from local recordings under screenshots/.
# Source .mov files are gitignored — run after placing:
#   录屏弹窗-浅色模式.mov · 录屏弹窗-浅色模式-en.mov
#   录屏全屏-浅色模式.mov · 录屏全屏-浅色模式-en.mov
# From repo root: bash scripts/regenerate_light_mode_demo_gifs.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/screenshots"

FF_FLOAT='[0:v]fps=10,scale=560:-2:flags=lanczos,format=gbrp,split[a][b];[a]palettegen=reserve_transparent=0:stats_mode=diff:max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:new=1'
FF_FULL='[0:v]fps=8,scale=620:-2:flags=lanczos,format=gbrp,split[a][b];[a]palettegen=reserve_transparent=0:stats_mode=diff:max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:new=1'

one() {
  local src="$1" dst="$2" filt="$3"
  if [[ ! -f "$src" ]]; then
    echo "Missing $src — add under screenshots/ first." >&2
    exit 1
  fi
  ffmpeg -y -ss 0 -i "$src" -t 1 -filter_complex "$filt" -loop 0 "$dst"
  echo "Wrote screenshots/$dst"
}

one "录屏弹窗-浅色模式.mov" "floating-reminder-demo-light.gif" "$FF_FLOAT"
one "录屏弹窗-浅色模式-en.mov" "floating-reminder-demo-light-en.gif" "$FF_FLOAT"
one "录屏全屏-浅色模式.mov" "fullscreen-overlay-demo-light.gif" "$FF_FULL"
one "录屏全屏-浅色模式-en.mov" "fullscreen-overlay-demo-light-en.gif" "$FF_FULL"
