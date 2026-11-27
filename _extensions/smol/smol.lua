-- Adds back what minimal: true leaves out and a site needs (see AGENTS.md).

-- Quarto doesn't pass website settings to filters, so read _quarto.yml.

local function read(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local text = file:read("a")
  file:close()
  return text
end

local function yaml(text)
  if not text then return nil end
  local ok, doc = pcall(pandoc.read, "---\n" .. text .. "\n---\n", "markdown")
  return ok and doc.meta or nil
end

local function str(value)
  return value ~= nil and pandoc.utils.stringify(value) or ""
end

local function escape(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

-- Quarto turns .qmd links into .html links later.
local function href(target)
  if target:match("^%a[%w+.-]*:") or target:match("^#") then return target end
  return (quarto.project.offset or ".") .. "/" .. target:gsub("^/", "")
end

local function website()
  local dir = quarto.project.directory
  if not dir then return nil end
  local config = yaml(read(pandoc.path.join({ dir, "_quarto.yml" })))
  if not config or str(config.project and config.project.type) ~= "website" then return nil end
  local site = config.website or {}
  for _, profile in ipairs(quarto.project.profile or {}) do
    local extra = yaml(read(pandoc.path.join({ dir, "_quarto-" .. profile .. ".yml" })))
    for key, value in pairs(extra and extra.website or {}) do site[key] = value end
  end
  return site
end

local function page_title(path)
  local text = read(pandoc.path.join({ quarto.project.directory, path }))
  local meta = yaml(text and text:match("^%-%-%-\r?\n(.-)\r?\n%-%-%-"))
  return meta and meta.title and str(meta.title) or nil
end

local function nav_link(item, current)
  if pandoc.utils.type(item) ~= "table" then item = { href = item } end
  local target = str(item.href)
  local text = str(item.text)
  if text == "" then text = str(item["aria-label"]) end
  if text == "" and target ~= "" then text = page_title(target) or target end
  if text == "" then text = str(item.icon) end
  if target == "" then
    return text ~= "---" and ('<span class="menu-header">' .. escape(text) .. "</span>") or nil
  end
  local here = target:gsub("^/", "") == current and ' aria-current="page"' or ""
  return '<a href="' .. escape(href(target)) .. '"' .. here .. ">" .. escape(text) .. "</a>"
end

local function nav_list(list, class, current)
  if not list or #list == 0 then return "" end
  local out = {}
  for _, item in ipairs(list) do
    if pandoc.utils.type(item) == "table" and item.menu then
      local menu = {}
      for _, entry in ipairs(item.menu) do
        local a = nav_link(entry, current)
        if a then table.insert(menu, "<li>" .. a .. "</li>") end
      end
      table.insert(out, "<li><details><summary>" .. escape(str(item.text)) .. "</summary><ul>"
        .. table.concat(menu) .. "</ul></details></li>")
    else
      table.insert(out, "<li>" .. (nav_link(item, current) or "") .. "</li>")
    end
  end
  return '<ul class="' .. class .. '">' .. table.concat(out) .. "</ul>"
end

local function nav_html(site)
  local navbar = site.navbar
  if not navbar then return "" end
  local current = pandoc.path.make_relative(quarto.doc.input_file, quarto.project.directory)
  local title = site.title
  if navbar.title ~= nil then title = navbar.title end
  local logo = navbar.logo or site.logo
  local brand = ""
  if title or logo then
    brand = '<a class="site-title" href="' .. href("index.html") .. '">'
      .. (logo and ('<img src="' .. escape(href(str(logo))) .. '" alt=""> ') or "")
      .. (title and escape(str(title)) or "") .. "</a>"
  end
  -- Quarto adds a skip link only with Bootstrap.
  return '<a class="skip-link" href="#quarto-content">Skip to main content</a>'
    .. '<header class="site-header"><nav class="site-nav" aria-label="Site">' .. brand
    .. nav_list(navbar.left, "nav-left", current) .. nav_list(navbar.right, "nav-right", current)
    .. "</nav></header>"
end

-- RSS feeds take a post's text from main.content; listings go in #quarto-content.
local function page(doc)
  local site = website()
  local header = site and nav_html(site) or ""
  quarto.doc.include_text("before-body", header .. '<main class="content" id="quarto-content">')
  quarto.doc.include_text("after-body", "</main>")
end

local function meta_filter(meta)
  -- Quarto reads title-block-style only with Bootstrap.
  local style = meta["title-block-style"]
  if style == false or str(style) == "none" then meta["smol-no-title-block"] = true end
  -- Undo Pandoc's curly quotes, which break quoted font names in CSS.
  for _, key in ipairs({ "mainfont", "monofont" }) do
    if meta[key] then
      local css = pandoc.utils.stringify(meta[key]):gsub("“", '"'):gsub("”", '"'):gsub("‘", "'"):gsub("’", "'")
      meta[key] = pandoc.RawInline("html", css)
    end
  end
  return meta
end

return {
  { Meta = meta_filter },
  { Pandoc = page },
}
