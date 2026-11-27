#!/bin/sh
# Report the CSS and JS each page of a rendered site loads, gzipped:
# linked files plus inline <style> and <script> blocks. Page content,
# images and fonts don't count.
#
# Fails if a page goes over the budget or loads CSS or JS from another
# domain (AGENTS.md, rules 1 and 6). Pages with a listing get a bigger
# budget, because Quarto always adds 9 KB of listing JS to them.
#
# Usage: sh scripts/size.sh [site-dir] [budget] [listing-budget]
# Budgets are in bytes.

set -eu

site=${1:-demo/_site}
budget=${2:-10240}
listing_budget=${3:-20480}

[ -d "$site" ] || { echo "No site at $site. Render it first." >&2; exit 2; }

. "$(dirname "$0")/lib.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

find "$site" -name '*.html' | sort > "$tmp/pages"

printf '%-36s %8s %8s %6s %6s\n' "Page" "CSS KB" "JS KB" "Files" "Limit"
over=0
problems=0
while read -r page; do
  mkdir -p "$tmp/inline"
  rm -f "$tmp/inline"/*
  css=0 js=0 files=0
  resources "$page" "$tmp/inline" > "$tmp/res"
  while read -r kind ref; do
    case $kind in
      *-inline) path=$ref ;;
      *)
        case $ref in
          http://* | https://* | //*)
            echo "  $page loads $ref from another domain" >> "$tmp/problems"
            problems=1
            continue ;;
          data:*) continue ;;
        esac
        path=$(local_path "$site" "$page" "$ref")
        files=$((files + 1))
        if [ ! -f "$path" ]; then
          echo "  $page links to $ref, which doesn't exist" >> "$tmp/problems"
          problems=1
          continue
        fi ;;
    esac
    size=$(gz "$path")
    case $kind in
      css-*) css=$((css + size)) ;;
      js-*) js=$((js + size)) ;;
    esac
  done < "$tmp/res"
  limit=$budget
  if grep -q 'quarto-listing/list.min.js' "$tmp/res"; then limit=$listing_budget; fi
  flag=""
  if [ $((css + js)) -gt "$limit" ]; then flag="  over"; over=$((over + 1)); fi
  printf '%-36s %8s %8s %6s %6s%s\n' "${page#"$site"/}" "$(kb $css)" "$(kb $js)" "$files" "$(kb "$limit")" "$flag"
done < "$tmp/pages"

[ -f "$tmp/problems" ] && { echo; echo "Problems:"; cat "$tmp/problems"; }
echo
echo "Budget: $(kb "$budget") KB of CSS and JS per page, $(kb "$listing_budget") KB with a listing. Pages over: $over."
[ "$over" -eq 0 ] && [ "$problems" -eq 0 ]
