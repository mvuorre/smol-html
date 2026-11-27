#!/bin/sh
# Screenshot pages of a rendered site with headless Chrome or Chromium:
# phone (390 px) and desktop (1280 px) widths, light and dark mode.
#
# Usage: sh scripts/shots.sh [site-dir] [out-dir] [page.html ...]
# With no pages given, it takes every page. Set CHROME to the browser if
# it isn't found, and HEIGHT to change the window height (default 2400).

set -eu

site=${1:-demo/_site}
out=${2:-demo/_shots}
[ $# -gt 2 ] && shift 2 || set --

[ -d "$site" ] || { echo "No site at $site. Render it first." >&2; exit 2; }

if [ -z "${CHROME:-}" ]; then
  for c in chromium chromium-browser google-chrome google-chrome-stable \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium"; do
    if command -v "$c" > /dev/null 2>&1 || [ -x "$c" ]; then CHROME=$c; break; fi
  done
fi
[ -n "${CHROME:-}" ] || { echo "No Chrome or Chromium found. Set CHROME." >&2; exit 2; }

height=${HEIGHT:-2400}
root=$(cd "$site" && pwd)
mkdir -p "$out"

if [ $# -eq 0 ]; then
  set -- $(cd "$site" && find . -name '*.html' | sed 's|^\./||' | sort)
fi

for page in "$@"; do
  name=$(echo "${page%.html}" | tr '/' '-')
  for width in 390 1280; do
    # preferredColorScheme: 0 is dark, 1 is light. Set both explicitly so the
    # computer's own setting doesn't leak in.
    for scheme in light:1 dark:0; do
      "$CHROME" --headless --disable-gpu --no-sandbox --hide-scrollbars \
        --force-device-scale-factor=1 --window-size="$width,$height" \
        --blink-settings=preferredColorScheme="${scheme#*:}" \
        --screenshot="$out/$name-$width-${scheme%:*}.png" \
        "file://$root/$page" > /dev/null 2>&1
    done
  done
  echo "$page"
done
echo "Screenshots in $out"
