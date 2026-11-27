QUARTO ?= quarto

.PHONY: demo stock size size-stock shots shots-stock compare publish check clean

# Render the demo site with smol, into demo/_site.
demo:
	$(QUARTO) render demo

# Render the demo site with normal Quarto, into demo/_site-stock.
stock:
	$(QUARTO) render demo --profile stock

# Check the CSS and JS each page loads against the budget.
size:
	sh scripts/size.sh demo/_site

# The same numbers for normal Quarto, for comparison. Always over budget.
size-stock:
	-sh scripts/size.sh demo/_site-stock

# Screenshot every page: phone and desktop, light and dark.
# Pass PAGES="index.html article.html" to take only some.
shots:
	sh scripts/shots.sh demo/_site demo/_shots $(PAGES)

shots-stock:
	sh scripts/shots.sh demo/_site-stock demo/_shots-stock $(PAGES)

# Measure both builds, update the comparison table on the demo's home
# page, and render the demo again to show it.
compare: demo stock
	sh scripts/compare.sh
	$(QUARTO) render demo

# Render the demo with smol and push it to the gh-pages branch, which
# GitHub Pages serves. Needs the GitHub remote 'origin'.
publish:
	$(QUARTO) publish gh-pages demo

# Render and check sizes.
check: demo size

clean:
	rm -rf demo/_site demo/_site-stock demo/_shots demo/_shots-stock demo/.quarto
