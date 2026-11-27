# AGENTS.md

Guidance for anyone working on this repo, human or agent, with the decisions that the code doesn't explain.

## What this is

A Quarto extension that provides an HTML format without Bootstrap, Quarto's JavaScript or icon fonts. Pages should be small, fast and beautiful, and most Quarto HTML features should keep working.

It's for Matti's website (vuorre.com) first. Others are welcome to use it, so anything general is done the standard Quarto way, but we don't promise to cover every Quarto feature. It supports websites, blogs and single documents (including `embed-resources: true`), and not books, manuscripts or slides.

A site switches to smol by changing only `format:`, and can switch back the same way. So the extension reads Quarto's standard options (`website.navbar`, `toc`, `date-format` and so on) instead of inventing its own.

## Rules

1. **Small and fast.** What the format adds to a page (its CSS and JS, gzipped) must stay under 10 KB. Pages with a listing may have 20 KB, because Quarto always adds 9 KB of listing JS that smol can't remove. Content, images and fonts don't count. The size check enforces this.
2. **Less code is better.** Every CSS rule, option and line of Lua has to earn its place, old ones included. Delete what isn't needed.
3. **Use the simplest tool that works,** in this order: a Pandoc or Quarto option, CSS, a template partial, a Lua filter, JavaScript.
4. **JavaScript only where needed.** Pages load no JS by default. A feature that can't work without it (a copy button, search) gets a tiny plain script, added only to pages that use the feature. Those pages must still work with JS off.
5. **Degrade, don't break.** If we don't support a Quarto feature, its content must still render readably. List it under "What doesn't work" in the README.
6. **No outside requests.** The format loads nothing from other domains: no CDNs, web font services or trackers. (A site's own content may.)
7. **Modern browsers.** Target browsers from the last two years, which lets us use modern CSS and MathML. Older browsers get a plainer page that is still readable.
8. **No code execution needed.** Building the demo needs only Quarto. A demo page that runs code commits its frozen output.

## Working here

- **Decide small things, ask about big ones.** Make routine calls yourself and log them under Decisions below with a one-line reason. Ask first before design or visual choices, dropping a Quarto feature, adding a dependency, or changing direction.
- **Check Quarto's source, not your memory.** How Quarto behaves without Bootstrap is poorly documented. Read the source at the installed version's tag (github.com/quarto-dev/quarto-cli) before relying on it.
- **Verify before calling something done:**
  - The demo renders with no warnings.
  - The size check passes.
  - Screenshots at phone (390 px) and desktop (1280 px) widths, in light and dark mode, look right.
  - When a change touches a Quarto feature, compare with the same page in normal Quarto (`format: html`).
  - Accessibility doesn't fall below normal Quarto's: `cd demo && quarto call axe _site` (and `_site-stock`) writes a report to `demo/_axe-checks/`. The command is hidden and experimental in Quarto 1.11.
- **Scripts run on macOS and Linux.** Matti works on macOS; agents may run on Linux. Use POSIX shell and Make, with no GNU-only flags.

## Git

- Small commits, one logical change each. Bigger work goes on a feature branch (`feat/…`, `fix/…`).
- Commit messages: a short imperative subject line, then a body that says why.
- Commit as Matti with `vuorre@gmail.com` (set in the repo's git config). End the message with `Co-Authored-By: AI Assistant`: no email and no model name.
- Don't push. Matti pushes.

## Decisions

How smol works:

- smol builds on `minimal: true`. It sets `theme: none` and leaves out Quarto's base CSS, its code colours and the features that need JavaScript (tabset switching, copy buttons, section anchors, hover popups, responsive figures, code annotation popups). See `htmlFormatFeatureDefaults` in Quarto's source. A site's own options win over an extension's, so a site that sets `theme` gets Bootstrap back.
- On top of `minimal: true`, smol sets `html-math-method: mathml` (without Bootstrap, Quarto doesn't pass `--mathjax`, so display math would come out as raw `$$`), `mermaid-format: svg` (no 770 KB of Mermaid JS, but rendering needs Chrome), and `date-format: iso`. Its `styles.html` partial drops the inline CSS Pandoc and Quarto add; `smol.css` covers it.
- Where `minimal: true`'s output reads fine, smol styles it and adds nothing. Callouts are quotes with a bold title, tabsets show every tab in turn, footnotes go at the end, and there's no page footer. Rebuilding these cost about 130 lines of Lua and 70 of CSS, and margin footnotes needed Quarto's undocumented `QUARTO_FILTER_PARAMS`.
- One Lua filter adds back what a site can't do without: the navbar, and the `<main>` wrapper that Quarto's RSS feeds and listings need. Quarto builds both only with Bootstrap and doesn't pass `website` options to filters, so the filter reads the navbar from `_quarto.yml` itself.
- Books aren't supported, because their navigation (the chapter sidebar, previous and next links, search) is Quarto's Bootstrap-only site navigation. The navbar is worth rebuilding in Lua; a book's navigation isn't, for now.
- Listing pages keep Quarto's listing script. No option leaves it out, and removing it after rendering would break the one-line switch.
- `mainfont` and `monofont` set smol's font stacks, but `highlight-style` isn't supported: its themes have colours for one background, and smol's code colours follow light and dark mode.
- Accessibility matches normal Quarto's. smol adds the skip link Quarto adds only with Bootstrap. Its text is English, because Quarto passes no translations to filters. Code blocks, tables and math that scroll sideways get no `tabindex`, which axe flags: Chrome and Firefox let the keyboard scroll them anyway, and a tab stop on each would slow keyboard users down.
- `title-block-style: none` works (the filter passes it to the title block partial). `plain` looks like smol's normal title block, and banners aren't supported.
- Code line numbers were dropped, and listing page links got plainer styling, as not worth their CSS. Line-numbered code still reads fine without the numbers.
- smol leaves `google-scholar` off, because Zotero would then save every blog post as a journal article. Checked with Zotero's translation server (Docker image `zotero/translation-server`).

Choices of look and scope:

- Margin content floats right, as in Tufte CSS: floats keep notes next to their text without gaps, at any depth. Every page has the same frame, so the text doesn't jump sideways between pages.
- The text is centred on screens 80rem and wider, with the margin column hanging off its right side and the header lined up with the text. On narrower laptops it sits left of centre, because the margin column doesn't fit otherwise. Matti found the off-centre text distracting.
- The title block puts each author on their own line, says "Edited" where Quarto says "Modified", and shows the license as plain text on the dates line (Quarto's own filter gives it as `text` and `url`; Matti chose no link).
- Not now: the category list beside listings and copy buttons. Each would cost 0.3 to 0.5 KB.
- About pages (`about:` templates) are out of scope. Matti doesn't use them, so the demo has none and the README doesn't mention them.

The demo:

- It lives at vuorre.com/smol-html/, because GitHub Pages serves this repo's site under the account's custom domain. Quarto writes no `_publish.yml` for GitHub Pages.
- The `stock` profile builds it with normal Quarto plus smol's math and diagram settings (MathML and Mermaid as SVG), for the comparison table. Any site can set those, so leaving them out would credit smol with savings it doesn't make. The table gives sizes only. Load times needed Lighthouse run by hand (PageSpeed's API needs a key, and running Lighthouse locally needs Node), so they went stale whenever the demo changed. Size is what smol controls, and load time follows it.

## Later

- Ask Quarto for an option to leave out the listing script, and report that its fallback `.ratio` CSS gives videos no height.
- `website.sidebar`, page navigation and breadcrumbs.

## Writing

Plain English and short sentences, as in the README. Say what something does and why. Code comments explain why, not what.

## Layout

- `_extensions/smol/`: the extension (`_extension.yml`, CSS, a Lua filter, template partials).
- `demo/`: the demo site. Its home page is the README plus a tour of features that is also the test fixture. `demo/_extensions` links to the extension. The profiles `_quarto-smol.yml` (the default) and `_quarto-stock.yml` build it with smol or with normal Quarto.
- `scripts/`: the size and screenshot checks.
- `template.qmd`: the starter document that `quarto use template` copies. `.quartoignore` keeps everything else (the demo, scripts and Makefile) out of new projects; `quarto add` only ever installs `_extensions/`.
- `README.md`: the only user docs. The demo's home page includes it, then adds the feature tour and the size table. So the README must read well on GitHub and on the site: links are absolute, GitHub-only text goes in `<div class="content-hidden">` or `<span class="content-hidden">`, and it gives no measured figures, since GitHub can't include the generated table.

## Commands

- `make demo`: render the demo with smol into `demo/_site`.
- `make stock`: render it with normal Quarto into `demo/_site-stock`, to compare.
- `make size`: check each page's CSS and JS against the budget. `make check` renders first.
- `make shots`: screenshot every page at 390 and 1280 px, in light and dark mode, into `demo/_shots`. `PAGES="index.html article.html"` limits it to some pages. Set `CHROME` if the browser isn't found.
- `make compare`: measure both builds and update the size table in `demo/_comparison.md`, which the demo's home page includes.
- `make publish`: render the demo and push it to the `gh-pages` branch. GitHub Pages serves it at https://vuorre.com/smol-html/. Matti runs this.
- `quarto preview demo`: look at the demo while editing.

## Setting up

Agents on Linux: install Quarto 1.11.9 from its GitHub releases, then `chromium`, `fonts-stix` and `fonts-texgyre-math` with apt. Without a math font, screenshots of math lose their Greek letters. Set `QUARTO_CHROMIUM=/usr/bin/chromium`, or Quarto can't find Chromium to draw Mermaid diagrams and the render fails.
