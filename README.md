A small & fast [HTML format](https://quarto.org/docs/output-formats/html-basics.html) for [Quarto](https://quarto.org/) websites and documents.

`format: smol-html` removes Bootstrap and Quarto's JavaScript and icon fonts. As a result, HTML documents are smaller and load faster.<span class="content-hidden"> The [demo site](https://vuorre.com/smol-html/) shows smol examples and how much [smaller](https://vuorre.com/smol-html/#size) its pages are than Quarto's standard HTML outputs.</span>

## Use

Install the extension in your project:

```sh
quarto add mvuorre/smol-html
```

Then set the format in your YAML front matter:

```yaml
format: smol-html
```

## How it works and what it does

smol is Quarto's [`minimal: true` HTML](https://quarto.org/docs/output-formats/html-basics.html#minimal-html) with a custom stylesheet for a fast & minimalist look. `minimal: true` leaves out Bootstrap (it sets `theme: none`), Quarto's base CSS and code colours, and features that need JavaScript: tabset switching, copy buttons, hover previews and section links. Thus, Quarto writes plain HTML, and smol styles it a bit.

Then, smol adds or enables:

- a navbar built from `website.navbar`
- a page wrapper that RSS feeds and listings need. It also writes
- pages that load no math or diagram scripts
  - math rendering with MathML 
  - render-time drawing of Mermaid diagrams, 
- styling for otherwise plain features, such as callouts and tabsets

## What doesn't work

Most of Quarto's HTML features and options work as usual. These (and likely others) don't, mostly because `minimal: true` omits them:

- Bootstrap themes (the `theme: ` YAML setting) and their options
- Code `highlight-style` settings
- Search, sidebars, page navigation and breadcrumbs
- Category lists in listing pages
- The appendix with the license and citation (the license shows in the title block)
- Title block banners (`title-block-banner`). `title-block-style: none` works.
- Code line numbers (`code-line-numbers`, `.number-lines`)
- Tabsets. Their tabs show one after another, below a list of links to them.
- Callout types, icons and collapsing (callouts become quotes with bold titles)
- The site's footer (`page-footer`)
- Margin footnotes (`reference-location: margin`) go to the end of the page (margin notes work)
- Features that need JavaScript: copy buttons, hover previews, footnotes and cross-references, and a dark-mode toggle
  - System- or browser-preference for dark mode is supported, so users see what they want
- Grid classes for one screen size and up, such as `.g-col-md-6`
  - Plain ones such as `.g-col-6` work
- The `-left`, `-right` and `-inset` column classes show at text width
- Books, manuscripts and slides. A book's chapter sidebar, page links and search are Quarto's site navigation, which needs Bootstrap.

## Good to know

- Accessibility is at least as good as standard Quarto's: automated checks (axe-core) find fewer problems on smol pages than on the same pages in standard Quarto
- Pages follow the reader's light or dark setting
- With `google-scholar: true`, reference managers such as Zotero save a page with its authors, date, DOI and journal
- Text uses the computer's own sans-serif and monospace fonts, so pages download no fonts
  - Set `mainfont` and `monofont` to use others
  - smol loads no font files, so name fonts readers have, or add `@font-face` rules in your own CSS
- Math is MathML, which the browser draws with the computer's math font (which must therefore exist, and does by default on MacOS and Windows; Linux users can Linux)
- smol draws Mermaid diagrams when rendering and includes them as SVG, so pages don't load Mermaid's 770 KB of JavaScript
  - Rendering a page with a diagram therefore needs Chrome or Chromium, and takes a moment longer, also in `quarto preview`. 
  - If Quarto can't find a browser, run `quarto install chrome-headless-shell`, or set `mermaid-format: js` to go back to Quarto's default
- Sites using normal Quarto can save the same way, about 1 MB on a page with math and a diagram: set `html-math-method: mathml` and `mermaid-format: svg`.
- Quarto still adds small scripts that smol can't turn off: listings (9 KB), the `kbd` shortcode and Mermaid diagrams (under 1 KB each), and section links (3 KB) on sites that turn `anchor-sections` on

<div class="content-hidden">

## In this repo

- `_extensions/smol/` extension source
- `template.qmd` Quarto document starter template
- `demo/` is the site at [vuorre.com/smol-html](https://vuorre.com/smol-html/): smol's landing page, docs and test fixture. `make publish` puts it on GitHub Pages.
- `scripts/` and the `Makefile` check page sizes, take screenshots and update the comparison. [AGENTS.md](https://github.com/mvuorre/smol-html/blob/main/AGENTS.md) lists the commands.

## License

[CC0 1.0](https://github.com/mvuorre/smol-html/blob/main/LICENSE)

</div>
