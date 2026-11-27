# Shared by size.sh and compare.sh: source it, don't run it.

# Gzipped size of a file in bytes.
gz() { gzip -9 -c "$1" | wc -c | tr -d ' '; }

# Bytes as kilobytes with one decimal.
kb() { awk -v b="$1" 'BEGIN { printf "%.1f", b / 1024 }'; }

# resources PAGE DIR prints one line per resource the page loads:
# "<kind> <path>", where kind is css-file, js-file, css-inline or
# js-inline. Inline blocks are written to files in DIR to be measured.
resources() {
  awk -v dir="$2" '
    function attr(tag, name) {
      if (match(tag, name "=\"[^\"]*\""))
        return substr(tag, RSTART + length(name) + 2, RLENGTH - length(name) - 3)
      if (match(tag, name "='\''[^'\'']*'\''"))
        return substr(tag, RSTART + length(name) + 2, RLENGTH - length(name) - 3)
      return ""
    }
    { s = s $0 "\n" }
    END {
      n = 0
      while (match(s, /<(link|script|style)([ \t\n][^>]*)?>/)) {
        tag = substr(s, RSTART, RLENGTH)
        s = substr(s, RSTART + RLENGTH)
        if (tag ~ /^<link/) {
          if (tag ~ /rel="?stylesheet/) print "css-file " attr(tag, "href")
          continue
        }
        closing = (tag ~ /^<script/) ? "</script>" : "</style>"
        end = index(s, closing)
        body = substr(s, 1, end - 1)
        s = substr(s, end + length(closing))
        if (tag ~ /^<script/ && attr(tag, "src") != "") {
          print "js-file " attr(tag, "src")
        } else if (body ~ /[^ \t\n\r]/) {
          n++
          kind = (tag ~ /^<script/) ? "js" : "css"
          f = dir "/" kind "-" n
          printf "%s", body > f
          close(f)
          print kind "-inline " f
        }
      }
    }
  ' "$1"
}

# local_path SITE PAGE REF prints the file in SITE that REF, linked from
# PAGE, points to.
local_path() {
  ref=${3%%[?#]*}
  case $ref in
    /*)
      # Root-relative, as on 404 pages: /<site-url path>/site_libs/...
      # Drop leading folders until the file is found in the site.
      rel=${ref#/}
      while [ ! -f "$1/$rel" ] && [ "$rel" != "${rel#*/}" ]; do
        rel=${rel#*/}
      done
      echo "$1/$rel" ;;
    *) echo "$(dirname "$2")/$ref" ;;
  esac
}
