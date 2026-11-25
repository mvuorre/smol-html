# Plan: smol, a small Quarto HTML format

A Quarto format extension for websites and single documents: `format: smol-html`. No Bootstrap, no Quarto JavaScript, no icon fonts. Small, fast and beautiful, and a drop-in replacement for `format: html` on most sites. The rules and working style are in [AGENTS.md](AGENTS.md).

## Why

On vuorre.com, every page loaded about 190 KB of gzipped CSS and JS: Bootstrap CSS 67 KB, search 41, Bootstrap JS 23, hover popups 16, icon CSS 14, Quarto JS 13. On top of that came a 176 KB icon font for two icons. A prototype on the site with `theme: pandoc` cut the home page from 366 KB to 15 KB, and a post with math and code from 377 KB plus MathJax to 14 KB. It kept everything Quarto does at build time: listings, RSS, sitemap, aliases, cross-references, citations, Open Graph and Google Scholar tags.

The demo site confirms the numbers. With normal Quarto, every page loads about 82 KB of CSS and 105 KB of JS in 17 files, plus MathJax from a CDN on pages with math and on listing pages. Bare smol loads under 1 KB of inline CSS and no JS, apart from the exceptions in the audit below.

(The prototype's own plan is in the first commit, `d1c5c8f`.)

## Decisions

- **A format extension.** It bundles format defaults, CSS, template partials and Lua filters behind one `format:` line. A Bootstrap theme can't remove Bootstrap, and post-processing normal Quarto output is fragile. We can add a project-type extension later if sites need project-level defaults.
- **Its own repo,** used by vuorre.com. The site pins a released version; while developing, the extension can be symlinked into the site.
- **Name: smol.** The format is `smol-html`.
- **For vuorre.com first,** open to others. General things are done the standard Quarto way.
- **Scope:** websites and blogs, and single documents. Not books.
- **Drop-in.** smol reads Quarto's standard options (`website.navbar`, `page-footer`, …), so a site switches with one line and can switch back.
- **Look:** modern sans-serif, system fonts only (0 KB).
- **Layout:** a text column plus a right margin for the table of contents, margin notes, footnotes and captions. Phones get one column.
- **Dark mode** follows the OS setting. No toggle.
- **No JavaScript in v1.** That means no search, copy-code button, tabs or dark-mode toggle.
- **`minimal: true`.** It sets `theme: none` (no Bootstrap and no Pandoc stylesheet) and turns off every Quarto feature that needs JS. `theme: pandoc` would add Pandoc's 4 KB stylesheet, which our own CSS replaces anyway.
- **Math:** MathML (`html-math-method: mathml`). Pandoc writes it at build time, so no page loads a math script.
- **Budget:** at most 10 KB of gzipped CSS and JS per page, checked by `make size`. Pages with a listing may have 20 KB (next point).
- **Listing pages keep Quarto's listing JS** (9 KB of List.js for sorting, filtering and pagination). smol can't turn it off, and removing it after rendering would cost the one-line switch.
- **Mermaid diagrams are drawn at build time** (`mermaid-format: svg`). A diagram page loads a 0.8 KB script instead of 773 KB of Mermaid, but rendering it needs Chrome or Chromium.
- **Math uses the system's math font.** The README tells Linux users they may need to install one.
- **License:** CC0 1.0 (Matti's choice; it was MIT).
- **One linked stylesheet,** `smol.css`, cached across a site's pages; `embed-resources` inlines it. An empty `styles.html` partial drops the CSS Pandoc inlines in every page.
- **The margin uses floats,** as in Tufte CSS: the table of contents, margin notes and margin captions float into it. Unlike a grid, floats never leave gaps in the text and work at any depth; in a crowded margin, notes slide down instead of overlapping. Pages with nothing for the margin centre their text.
- **One Lua filter, run at pre-render,** for `<main>`, callouts, tabsets and margin footnotes. It reads translated titles and `reference-location` from Quarto's filter parameters (`QUARTO_FILTER_PARAMS`, undocumented), falling back to English and the defaults.
- **Callouts** show their type with colour and title, without icons (those would need an icon font or SVGs).
- **Dates** are ISO (`date-format: iso`). Sites can set their own `date-format`.
- **One page frame.** Every page keeps the text column and margin in the same place, so the text doesn't jump sideways between pages. Simpler than centring pages that have nothing in the margin.
- **Tables are centred,** like figures (Quarto has `fig-align` but no table option). Captions centre when they fit on one line and wrap left-aligned when they don't, as in LaTeX.
- **Scholarly metadata over a visible citation.** No "Citation" or BibTeX appendix. Instead, pages give reference managers good metadata. Checked with Zotero's own translation server (Docker image `zotero/translation-server`): with `google-scholar: true`, the demo article is saved as a journal article with authors, date, abstract, journal, volume, issue and DOI; without it, a blog post is saved as a web page with author, date and description. smol doesn't turn `google-scholar` on by default, because Zotero would then call every blog post a journal article.
- **The landing page** is the demo's home page, published on GitHub Pages from the private repo `mvuorre/smol-html`. GitHub serves it at vuorre.com/smol-html/, because the account's own site has that custom domain. It and the README show the size comparison, which `make compare` measures and updates. Below that, the home page shows the features, so visitors see smol at work without clicking through. It has no listing, which would add Quarto's 9 KB listing script; the blog lists the posts.
- **Navbar and footer** come from `website.navbar` and `website.page-footer`, read from `_quarto.yml` by the Lua filter, since Quarto doesn't pass them to filters. The navbar is one line of text links at the page's width, with no bar behind it. Menus are `<details>`.
- **Light and dark** follow the reader's system setting, documented in the README.
- **Quarto 1.11.** The latest stable release is 1.11.9.
- **A demo site in `demo/`** is both the docs and the test fixture. Two pages hold the features: the home page, with Quarto's default options, and `article.qmd`, a scholarly article with margin notes and footnotes. Profiles build it with smol or with normal Quarto.

## Audit: what survives without Bootstrap

Quarto 1.11.9, the demo site built with bare smol (`minimal: true`, MathML, no CSS of our own) and with `format: html`.

**Works, and only needs CSS:**

- Text: headings, lists, task and definition lists, quotes, line blocks, inline formatting
- Code: highlighting classes (but no colours), file names, line numbers, code folding (`<details>`), annotations (numbered markers and a list), cell output
- Math as MathML, with equation numbers and cross-references
- Figures, subfigures, tables, captions and their cross-references
- Theorems, proofs and definitions
- Citations, the bibliography, and footnotes at the end of the page
- Margin and wide content keep their classes: `column-margin`, `column-page`, `column-screen`, `column-body-outset`, asides and margin captions
- Quarto's `layout-ncol` panels and Pandoc's columns
- The table of contents (Pandoc's, at the top of the page)
- Listing items with their classes, the sitemap, and Open Graph tags

**Works, but broken:**

- **RSS:** every item's content is `undefined`. Quarto takes it from `<main class="content">`, which the page doesn't have.
- **Listings** show Quarto's "No matching items" note under every listing; it's hidden by Bootstrap's `d-none` class.
- **Listing pages load 9 KB of JS** (List.js) for sorting, filtering and pagination. Quarto always adds it to pages with a listing, and no option turns it off. With pagination, the script removes items from the page and the page links show as an unstyled list.
- **Callouts** become a blockquote with a bold title. Their type, appearance, icon and collapse are lost.
- **Tabsets** become a list of tab links, followed by all the panels without their titles.
- **Footnotes** stay at the end even with `reference-location: margin`.
- **Title block:** Pandoc's (title, subtitle, authors, date, abstract). The date isn't formatted (`2026-10-15`), and there's no description, affiliations, ORCID, DOI, categories or modified date.
- **Mermaid** loads 773 KB of JS. With `mermaid-format: svg`, Quarto draws the diagram at build time with Chrome and inlines the SVG, leaving a 0.8 KB script. Rendering then needs Chrome or Chromium.
- **The `kbd` shortcode** adds 0.7 KB of JS and CSS to pages that use it.
- **Math needs a math font.** Without one, Greek and script letters disappear (seen on Linux without math fonts). Macs and Windows have one. Brackets also don't stretch unless `<math>` uses a math font.

**Gone:**

- The navbar, page footer, search and sidebar
- The `<main>` element
- About-page templates: only the title and text are left
- The category list beside listings
- The appendix: license ("Reuse") and citation with BibTeX
- Copy-code buttons, section anchors and hover popups (turned off by `minimal`)

## Not supported in v1

- Search, copy-code buttons, tabs as tabs, a dark-mode toggle, hover popups for citations and footnotes
- Callout icons
- The `-left`, `-right` and `-inset` column classes (they show at text width)
- Books

## Roadmap

### 0. Setup

- [x] git repo, `AGENTS.md`, `CLAUDE.md` (imports `AGENTS.md`), `.gitignore`
- [x] Rename the extension to smol
- [x] Quarto 1.11.9 and headless Chromium where agents run
- [x] `demo/`: one page per group of features, three posts, listings, an about page and a 404 page. It uses the extension through a symlinked `_extensions/`.
- [x] Makefile: `make demo`, `make stock`, `make size`, `make shots`

### 1. Audit

- [x] Build the demo with bare smol and with normal Quarto, and compare (above)
- [x] `theme: none` (through `minimal: true`), not `theme: pandoc`

### 2. Document page

First pass done and reviewed once.

- [x] Our own CSS, replacing the Pandoc rules Quarto inlines (4.4 KB gzipped)
- [x] Type and colour: system sans-serif, monospace and math font stacks, sizes, line length, spacing; light and dark
- [x] Layout: text plus a right margin; Quarto's `column-*` classes; one column on phones
- [x] Title block: title, subtitle, description, authors and affiliations, formatted dates, categories, DOI
- [x] Table of contents in the margin
- [x] Footnotes in the margin with `reference-location: margin`
- [x] Code: highlighting colours for light and dark, folding, file names, annotations, cell output
- [x] Callouts, with a colour per type and collapse via `<details>`
- [x] Tabsets as stacked sections with their titles
- [x] Figures, tables, cross-references, citations, theorems, math
- [x] Self-contained documents (`embed-resources: true`)
- [x] First review on a Mac: tighter spacing, ORCID icon, plain DOI, ISO dates, screen-wide images, fewer demo pages
- [ ] Margin captions start at the bottom of their figure or table; table captions would read better at the top

### 3. Website

- [x] `<main class="content" id="quarto-content">`, so RSS gets full content
- [x] Navbar from `website.navbar`, page footer from `website.page-footer`
- [ ] Listings (default, grid, table) without the "No matching items" note
- [ ] 404 page, sitemap, Open Graph tags. The 404 page loads `smol.css` from a copy Quarto puts in `_site/_extensions/smol/`, not from `site_libs/` like other pages; it works, but readers download the CSS twice.

### 3b. Scholarly metadata

- [x] Zotero picks up scholarly pages (with `google-scholar: true`) as journal articles, and other pages as web pages

### 4. Try it on vuorre.com

- [ ] Symlink the extension into the site, switch with `format: smol-html`, fix what breaks
- [ ] Measure page weight before and after

### 5. Release

- [x] Size comparison with normal Quarto (`make compare`), on the landing page and in the README
- [ ] Speed: load times in a real browser, for example with PageSpeed Insights once the site is public
- [x] `.quartoignore`, so `quarto use template` copies only `template.qmd` and the extension (checked locally, as was `quarto add`)
- [x] GitHub repo `mvuorre/smol-html`; `site-url`, the GitHub links and the install line point to it
- [ ] Publish the demo on GitHub Pages with `make publish` (`quarto publish gh-pages demo`), and commit the `demo/_publish.yml` Quarto writes
- [ ] Maybe: a GitHub Action that publishes on every push
- [ ] README: install, use, what's supported and what isn't
- [ ] `template.qmd` shows off the format
- [x] License: CC0 1.0
- [ ] Tag v0.1.0

## Later

- [ ] Search: a page with a tiny script over `search.json` (Quarto still writes it), Pagefind, or a `site:` web-search form
- [ ] Ask Quarto for an option to leave out the listing JS
- [ ] Opt-in scripts: copy-code button, real tabs, dark-mode toggle
- [ ] About-page templates
- [ ] Show license, copyright and funding at the end of a page (normal Quarto's "Reuse" appendix, without the citation)
- [ ] Try smol with q2 (Quarto 2, the experimental rewrite in Rust). It does websites, listings and navbars, but its extension docs only cover TypeScript engines so far, so Lua filters and template partials may not run there yet.
- [ ] `website.sidebar`, page navigation, breadcrumbs
- [ ] Books
