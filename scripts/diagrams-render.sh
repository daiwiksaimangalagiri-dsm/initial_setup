#!/usr/bin/env bash
# Render Mermaid files to SVG + PNG using your installed Google Chrome (no bundled Chromium).
#   diagram-render file.mmd [more.mmd ...]    writes file.svg and file.png next to each input
set -euo pipefail
[ $# -ge 1 ] || { echo "usage: diagram-render <file.mmd> [...]"; exit 1; }

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[ -x "$CHROME" ] && export PUPPETEER_EXECUTABLE_PATH="${PUPPETEER_EXECUTABLE_PATH:-$CHROME}"
[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1
command -v mmdc >/dev/null || { echo "mmdc not found: run initial-setup"; exit 1; }

for f in "$@"; do
  base="${f%.*}"
  mmdc -q -i "$f" -o "$base.svg"
  mmdc -q -i "$f" -o "$base.png" -s 2 -b white
  echo "rendered $base.svg and $base.png"
done
