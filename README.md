# smol

A small, fast HTML format for Quarto websites and documents: no Bootstrap, no Quarto JavaScript, no icon fonts. Listings, RSS, citations, cross-references, callouts and margin notes still work. See it at [vuorre.com/smol-html](https://vuorre.com/smol-html/). It's a work in progress; see [PLAN.md](PLAN.md).

<!-- comparison -->
| Page | Normal Quarto | smol |
|:-----------------------------------|-------------------:|------------------:|
| Home page, with code, math and a diagram | 1.4 MB in 26 files | 16 KB in 5 files |
| Article with math and citations | 612 KB in 21 files | 9.2 KB in 2 files |
| Blog page with a listing | 617 KB in 23 files | 16 KB in 4 files |
| Blog post | 365 KB in 19 files | 6.3 KB in 2 files |

What each page downloads: HTML, CSS and JavaScript (gzipped), and fonts. Normal Quarto runs 105 KB of JavaScript on a plain blog post; smol runs none. Quarto still adds a small script for a few features: listings (9 KB), and keyboard keys and Mermaid diagrams (under 1 KB each). Measured on this site's pages with Quarto 1.11.9. With normal Quarto, pages with math also download MathJax's fonts, which aren't counted.
<!-- /comparison -->

## Use

Install the extension in your project's folder:

``` sh
quarto add mvuorre/smol-html
```

Then, in a website's `_quarto.yml`, or a document's front matter:

``` yaml
format: smol-html
```

## What's in this repo

- `_extensions/smol/`: the extension. It's all that `quarto add` installs.
- `template.qmd`: the starter document for `quarto use template`. `.quartoignore` keeps the rest of the repo out of new projects.
- `demo/`: the website at [vuorre.com/smol-html](https://vuorre.com/smol-html/), which is smol's landing page, docs and test site. It's built with the extension in this repo and published to GitHub Pages with `make publish` (`quarto publish gh-pages demo`).
- `scripts/` and the `Makefile`: development checks for page sizes, screenshots and the comparison.

## Good to know

- **Light and dark** follow the reader's system setting (light or dark mode in the OS or browser). There's no toggle.
- **The navbar and page footer** come from the usual `website: navbar:` and `page-footer:` settings, as a plain line of links. Search and sidebars aren't supported.
- **Dates** are ISO (2026-11-25). Set `date-format` in `_quarto.yml` for another format.
- **Scholarly pages:** set `google-scholar: true` so reference managers like Zotero pick up the authors, dates, DOI and journal.
- **Math** is MathML, which the browser draws with the computer's math font. Macs and Windows have one. On Linux, install one (for example STIX Two Math, Latin Modern Math or a TeX Gyre math font), or Greek and script letters in equations may not show.
- **Mermaid diagrams** are drawn when the page is rendered and included as SVG, so pages don't load Mermaid's 770 KB of JavaScript. Rendering a page with a diagram therefore needs Chrome or Chromium, and takes a moment longer, also in `quarto preview`. If Quarto can't find one, run `quarto install chrome-headless-shell`, or set `mermaid-format: js` to go back to Quarto's default.
- **A few features bring a small script from Quarto:** listings (about 9 KB), keyboard keys from the `kbd` shortcode, and Mermaid diagrams (under 1 KB each). smol can't turn off the listing script.

## License

[CC0 1.0](LICENSE): no rights reserved.
