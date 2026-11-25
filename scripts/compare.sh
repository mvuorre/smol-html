#!/bin/sh
# Compare what pages download with normal Quarto and with smol: gzipped
# HTML, CSS and JavaScript, fonts, and the number of files. Writes a
# Markdown table to demo/_comparison.md, which the demo's home page
# includes, and into README.md between the comparison markers.
#
# Usage: sh scripts/compare.sh (after rendering both builds; make compare
# does everything).

set -eu
. "$(dirname "$0")/lib.sh"

stock=demo/_site-stock
smol=demo/_site
out=demo/_comparison.md
pages="index.html|Home page, with code, math and a diagram
article.html|Article with math and citations
blog.html|Blog page with a listing
posts/welcome/index.html|Blog post"

for site in "$stock" "$smol"; do
  [ -d "$site" ] || { echo "No site at $site. Run make compare." >&2; exit 2; }
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
touch "$tmp/remote"

# Size of a file on another site, compressed as the server sends it.
remote() {
  cached=$(awk -v u="$1" '$1 == u { print $2 }' "$tmp/remote")
  if [ -z "$cached" ]; then
    cached=$(curl -sL --compressed -o /dev/null -w '%{size_download}' "$1" || echo 0)
    [ "$cached" -gt 0 ] || echo "Couldn't fetch $1; counting it as 0 bytes." >&2
    echo "$1 $cached" >> "$tmp/remote"
  fi
  echo "$cached"
}

# measure SITE PAGE prints "FILES BYTES JS-BYTES" for what the page downloads.
measure() {
  page=$1/$2
  files=1
  bytes=$(gz "$page")
  js=0
  mkdir -p "$tmp/inline"
  resources "$page" "$tmp/inline" > "$tmp/res"
  while read -r kind ref; do
    case $kind in
      *-inline)
        # Already counted as part of the HTML.
        case $kind in js-*) js=$((js + $(gz "$ref"))) ;; esac
        continue ;;
    esac
    case $ref in
      data:*) continue ;;
      http://* | https://* | //*) size=$(remote "$ref") ;;
      *) size=$(gz "$(local_path "$1" "$page" "$ref")") ;;
    esac
    files=$((files + 1))
    bytes=$((bytes + size))
    case $kind in js-*) js=$((js + size)) ;; esac
  done < "$tmp/res"
  # Bootstrap's icon font downloads when the page shows an icon.
  if grep -q 'class="bi bi-' "$page"; then
    font=$(find "$1" -name 'bootstrap-icons.woff2' | head -n 1)
    [ -n "$font" ] || font=$(find "$1" -name 'bootstrap-icons.woff' | head -n 1)
    if [ -n "$font" ]; then
      files=$((files + 1))
      bytes=$((bytes + $(wc -c < "$font" | tr -d ' ')))
    fi
  fi
  echo "$files $bytes $js"
}

size() {
  awk -v b="$1" 'BEGIN {
    k = b / 1024
    if (k >= 1000) printf "%.1f MB", k / 1024
    else printf(k < 10 ? "%.1f KB" : "%.0f KB", k)
  }'
}

printf '%s\n' "$pages" > "$tmp/pages"
{
  echo "| Page | Normal Quarto | smol |"
  # Pandoc sizes the columns of long tables by these dashes.
  echo "|:-----------------------------------|-------------------:|------------------:|"
  while IFS='|' read -r page label; do
    set -- $(measure "$stock" "$page")
    before="$(size "$2") in $1 files"
    stock_js=$3
    set -- $(measure "$smol" "$page")
    echo "| $label | $before | $(size "$2") in $1 files |"
    if [ "$page" = posts/welcome/index.html ]; then echo "$stock_js" > "$tmp/js"; fi
  done < "$tmp/pages"
  echo
  echo "What each page downloads: HTML, CSS and JavaScript (gzipped), and fonts." \
    "Normal Quarto runs $(size "$(cat "$tmp/js")") of JavaScript on a plain blog post;" \
    "smol runs none. Quarto still adds a small script for a few features:" \
    "listings (9 KB), and keyboard keys and Mermaid diagrams (under 1 KB each)." \
    "Measured on this site's pages with Quarto $(quarto --version)." \
    "With normal Quarto, pages with math also download MathJax's fonts, which aren't counted."
} > "$out"

# Copy the table into the README, between <!-- comparison --> and
# <!-- /comparison -->.
awk -v table="$out" '
  /<!-- \/comparison -->/ { skip = 0 }
  !skip { print }
  /<!-- comparison -->/ { while ((getline line < table) > 0) print line; skip = 1 }
' README.md > "$tmp/readme"
cp "$tmp/readme" README.md

cat "$out"
