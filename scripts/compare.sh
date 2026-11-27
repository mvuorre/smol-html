#!/bin/sh
# Compare what pages download with normal Quarto and with smol (gzipped
# HTML, CSS and JavaScript, and fonts). Writes a Markdown table to
# demo/_comparison.md, which the demo's home page includes.
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
blog.html|Blog page with three listings
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

# measure SITE PAGE prints "BYTES JS-BYTES" for what the page downloads.
measure() {
  page=$1/$2
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
    bytes=$((bytes + size))
    case $kind in js-*) js=$((js + size)) ;; esac
  done < "$tmp/res"
  # Bootstrap's icon font downloads when the page shows an icon.
  if grep -q 'class="bi bi-' "$page"; then
    font=$(find "$1" -name 'bootstrap-icons.woff2' | head -n 1)
    [ -n "$font" ] || font=$(find "$1" -name 'bootstrap-icons.woff' | head -n 1)
    [ -z "$font" ] || bytes=$((bytes + $(wc -c < "$font" | tr -d ' ')))
  fi
  echo "$bytes $js"
}

# smol's size as a percentage of normal Quarto's.
percent() {
  awk -v a="$1" -v b="$2" 'BEGIN { p = 100 * a / b; printf(p < 9.95 ? "%.1f%%" : "%.0f%%", p) }'
}

size() {
  awk -v b="$1" 'BEGIN {
    k = b / 1024
    if (k >= 1000) printf "%.1f&nbsp;MB", k / 1024
    else printf(k < 9.95 ? "%.1f&nbsp;KB" : "%.0f&nbsp;KB", k) # 9.96 is 10 KB, not 10.0
  }'
}

printf '%s\n' "$pages" > "$tmp/pages"
{
  echo "| Page | Normal Quarto | smol | Relative size |"
  # Pandoc sizes the columns of long tables by these dashes.
  echo "|:-----------------------------------|-------------------:|------------------:|------------------:|"
  while IFS='|' read -r page label; do
    set -- $(measure "$stock" "$page")
    stock_bytes=$1
    stock_js=$2
    set -- $(measure "$smol" "$page")
    echo "| $label | $(size "$stock_bytes") | $(size "$1") | $(percent "$1" "$stock_bytes") |"
    if [ "$page" = posts/welcome/index.html ]; then echo "$stock_js" > "$tmp/js"; fi
  done < "$tmp/pages"
  echo
  echo "Sizes include HTML, CSS and JavaScript (gzipped), and fonts, measured with Quarto $(quarto --version)." \
    "Relative size is smol's size as a percentage of normal Quarto's." \
    "Normal Quarto here writes math as MathML and draws diagrams when rendering, as smol does, instead of loading MathJax and Mermaid." \
    "Normal Quarto runs $(size "$(cat "$tmp/js")") of JavaScript on a plain blog post; smol runs none."
} > "$out"

cat "$out"
