# AGENTS.md

Guidance for anyone working on this repo, human or agent. Read [PLAN.md](PLAN.md) too: it has the roadmap, the decisions and what we learned from the prototype.

## What this is

A Quarto extension that provides an HTML format without Bootstrap, Quarto's JavaScript or icon fonts. Pages should be small, fast and beautiful, and most Quarto HTML features should keep working.

- **For:** Matti's website (vuorre.com) first. Others are welcome to use it, so anything general is done the standard Quarto way. We don't promise to cover every Quarto feature.
- **Supports:** websites and blogs, and single documents (including `embed-resources: true`). Not books, manuscripts or slides.
- **Drop-in:** a site switches to this format by changing only `format:`, and can switch back. So the extension reads Quarto's standard options (`website.navbar`, `page-footer`, `toc`, callouts, …) instead of inventing its own.

## Rules

1. **Small and fast.** What the format adds to a page (its CSS and JS, gzipped) must stay under 10 KB. Pages with a listing may have 20 KB, because Quarto always adds 9 KB of listing JS that smol can't remove. Content, images and fonts don't count. The size check enforces this.
2. **Less code is better.** Every CSS rule, option and line of Lua has to earn its place, old ones included. Delete what isn't needed.
3. **Use the simplest tool that works,** in this order: a Pandoc or Quarto option, CSS, a template partial, a Lua filter, JavaScript.
4. **JavaScript only where needed.** Pages load no JS by default. A feature that can't work without it (copy button, tabs, search) gets a tiny plain script, added only to pages that use the feature. Those pages must still work with JS off.
5. **Degrade, don't break.** If we don't support a Quarto feature, its content must still render readably. List it under "Not supported" in PLAN.md.
6. **No outside requests.** The format loads nothing from other domains: no CDNs, web font services or trackers. (A site's own content may.)
7. **Modern browsers.** Target browsers from the last two years, which lets us use modern CSS and MathML. Older browsers get a plainer page that is still readable.
8. **No code execution needed.** Building the demo needs only Quarto. A demo page that runs code commits its frozen output.

## Working here

- **Decide small things, ask about big ones.** Make routine calls yourself and log them in PLAN.md with a one-line reason. Ask first before design or visual choices, dropping a Quarto feature, adding a dependency, or changing the plan.
- **Check Quarto's source, not your memory.** How Quarto behaves without Bootstrap is poorly documented. Read the source at the installed version's tag (github.com/quarto-dev/quarto-cli) before relying on it.
- **Verify before calling something done:**
  - The demo renders with no warnings.
  - The size check passes.
  - Screenshots at phone (390 px) and desktop (1280 px) widths, in light and dark mode, look right.
  - When a change touches a Quarto feature, compare with the same page in normal Quarto (`format: html`).
- **Scripts run on macOS and Linux.** Matti works on macOS; agents may run on Linux. Use POSIX shell and Make, with no GNU-only flags.

## Git

- Small commits, one logical change each. Bigger work goes on a feature branch (`feat/…`, `fix/…`).
- Commit messages: a short imperative subject line, then a body that says why.
- Don't push. Matti pushes.

## Writing

Plain English and short sentences, as in PLAN.md. Say what something does and why. Code comments explain why, not what.

## Layout

- `_extensions/smol/`: the extension (`_extension.yml`, CSS, Lua filters, template partials).
- `demo/`: the demo site, which is both the docs and the test fixture. `demo/_extensions` links to the extension. The profiles `_quarto-smol.yml` (the default) and `_quarto-stock.yml` build it with smol or with normal Quarto.
- `scripts/`: the size and screenshot checks.
- `template.qmd`: the starter document that `quarto use template` copies. `.quartoignore` keeps everything else (the demo, scripts, Makefile, PLAN.md) out of new projects; `quarto add` only ever installs `_extensions/`.
- `PLAN.md`: roadmap, decisions, audit.

## Commands

- `make demo`: render the demo with smol into `demo/_site`.
- `make stock`: render it with normal Quarto into `demo/_site-stock`, to compare.
- `make size`: check each page's CSS and JS against the budget. `make check` renders first.
- `make shots`: screenshot every page at 390 and 1280 px, in light and dark mode, into `demo/_shots`. `PAGES="index.html article.html"` limits it to some pages. Set `CHROME` if the browser isn't found.
- `make compare`: measure both builds and update the size comparison in `demo/_comparison.md` and the README.
- `make publish`: render the demo and push it to the `gh-pages` branch. GitHub Pages serves it at https://vuorre.com/smol-html/. Matti runs this.
- `quarto preview demo`: look at the demo while editing.

## Setting up

Agents on Linux: install Quarto 1.11.9 from its GitHub releases, then `chromium`, `fonts-stix` and `fonts-texgyre-math` with apt. Without a math font, screenshots of math lose their Greek letters. Set `QUARTO_CHROMIUM=/usr/bin/chromium`, or Quarto can't find Chromium to draw Mermaid diagrams and the render fails.
