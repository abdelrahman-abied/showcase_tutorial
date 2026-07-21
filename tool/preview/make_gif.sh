#!/usr/bin/env bash
#
# Stitches the two frame sequences written by capture_step_transition.dart into
# preview/step_transition.gif — the default (instant) tour on the left, the
# glide on the right, playing in lockstep.
#
#   flutter test tool/preview/capture_step_transition.dart   # writes the frames
#   tool/preview/make_gif.sh                                 # writes the GIF
#
# Needs ffmpeg and gifsicle (brew install ffmpeg gifsicle).

set -euo pipefail

cd "$(dirname "$0")/../.."

FRAMES="build/preview_frames"
OUT="preview/step_transition.gif"
FPS=20
# Half-width of the final GIF. The frames are captured at 2x this, so the
# downscale sharpens them.
PANE=360
# A hairline between the two panes so they don't read as one screen.
DIVIDER=0x123044

for variant in instant glide; do
  if [ ! -d "$FRAMES/$variant" ]; then
    echo "error: $FRAMES/$variant is missing — run the capture first:" >&2
    echo "  flutter test tool/preview/capture_step_transition.dart" >&2
    exit 1
  fi
done

for tool in ffmpeg gifsicle; do
  command -v "$tool" >/dev/null || { echo "error: $tool not on PATH" >&2; exit 1; }
done

echo "==> encoding $OUT"
# A single pass: scale each side, pad a divider onto the left one, stack them,
# then generate a palette from the stacked result and apply it. Sharing one
# palette across both panes keeps the colours identical on each side.
ffmpeg -hide_banner -loglevel error -y \
  -framerate "$FPS" -i "$FRAMES/instant/frame_%04d.png" \
  -framerate "$FPS" -i "$FRAMES/glide/frame_%04d.png" \
  -filter_complex "\
    [0:v]scale=$PANE:-1:flags=lanczos,pad=iw+2:ih:0:0:color=$DIVIDER[left]; \
    [1:v]scale=$PANE:-1:flags=lanczos[right]; \
    [left][right]hstack=inputs=2,split[stacked][forpalette]; \
    [forpalette]palettegen=max_colors=128:stats_mode=diff[palette]; \
    [stacked][palette]paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle" \
  -loop 0 "$OUT"

echo "==> optimizing"
# --lossy trades a little banding in the scrim for a much smaller archive; the
# package ships inside a pub.dev download, so bytes matter.
gifsicle -O3 --lossy=60 --colors 128 -b "$OUT"

echo "==> done: $OUT ($(du -h "$OUT" | cut -f1))"
