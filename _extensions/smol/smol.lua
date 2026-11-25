-- smol's Lua filter. It runs at pre-render: after Quarto has numbered
-- cross-references, while callouts and tabsets are still Quarto's own nodes.

-- Quarto's settings for filters (translated titles, reference-location).
-- They arrive as base64 JSON in an undocumented environment variable, so
-- read them defensively: without them, smol uses English and the defaults.
local params = {}
do
  local raw = os.getenv("QUARTO_FILTER_PARAMS")
  if raw then
    local ok, decoded = pcall(function()
      local _, json = pandoc.mediabag.fetch("data:application/json;base64," .. raw)
      return pandoc.json.decode(json, false)
    end)
    if ok and type(decoded) == "table" then params = decoded end
  end
end

local function param(key, default)
  local value = params[key]
  if type(value) == "string" and value ~= "" then return value end
  return default
end

local function capitalize(s)
  return s:sub(1, 1):upper() .. s:sub(2)
end

local function html(inlines)
  return pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), "html")
end

-- Callouts. Without Bootstrap, Quarto renders them as plain blockquotes and
-- drops their type. Keep the type as a class, and use <details> for
-- callouts that collapse.
local function callout(node)
  local kind = node.type or "note"
  local title = quarto.utils.as_inlines(node.title) or pandoc.Inlines({})
  local name = param("callout-" .. kind .. "-title", capitalize(kind))

  -- Cross-referenced callouts get a number, as in "Note 1: Title".
  local order = type(node.order) == "table" and node.order.order or node.order
  if node.attr.identifier ~= "" and type(order) == "number" then
    local prefix = name .. " " .. order
    if #title > 0 then
      title = pandoc.Inlines({ pandoc.Str(prefix .. ":"), pandoc.Space() }) .. title
    else
      title = pandoc.Inlines({ pandoc.Str(prefix) })
    end
  elseif #title == 0 and (node.appearance == nil or node.appearance == "default") then
    title = pandoc.Inlines({ pandoc.Str(name) })
  end

  local classes = { "callout", "callout-" .. kind }
  if node.appearance == "simple" or node.appearance == "minimal" then
    table.insert(classes, "callout-" .. node.appearance)
  end

  local content = quarto.utils.as_blocks(node.content) or pandoc.Blocks({})
  local blocks = pandoc.Blocks({})
  local collapse = node.collapse
  if collapse ~= nil and collapse ~= "" then
    local open = (collapse == false or collapse == "false") and " open" or ""
    blocks:insert(pandoc.RawBlock("html", "<details" .. open .. "><summary class=\"callout-title\">"
      .. html(title) .. "</summary>"))
    blocks:extend(content)
    blocks:insert(pandoc.RawBlock("html", "</details>"))
  else
    if #title > 0 then
      blocks:insert(pandoc.Div(pandoc.Plain(title), pandoc.Attr("", { "callout-title" })))
    end
    blocks:extend(content)
  end
  return pandoc.Div(blocks, pandoc.Attr(node.attr.identifier, classes))
end

-- Tabsets. Without JavaScript, show the tabs one after another, each with
-- its title. (The titles aren't headings, so they stay out of the table of
-- contents, as with Quarto's own tabs.)
local function tabset(node)
  local tabs = pandoc.Blocks({})
  for _, tab in ipairs(node.tabs) do
    local inner = pandoc.Blocks({
      pandoc.Div(pandoc.Plain(quarto.utils.as_inlines(tab.title)), pandoc.Attr("", { "tab-title" })),
    })
    inner:extend(quarto.utils.as_blocks(tab.content) or pandoc.Blocks({}))
    tabs:insert(pandoc.Div(inner, pandoc.Attr("", { "tab" })))
  end
  local attr = node.attr:clone()
  if not attr.classes:includes("panel-tabset") then attr.classes:insert("panel-tabset") end
  return pandoc.Div(tabs, attr)
end

-- Footnotes in the margin, for reference-location: margin. Quarto only does
-- this with Bootstrap. Each note goes in a margin div after the block that
-- refers to it.
local function margin_footnotes(doc)
  local n = 0
  local blocks = pandoc.Blocks({})
  for _, block in ipairs(doc.blocks) do
    local notes = {}
    block = block:walk({
      Note = function(note)
        n = n + 1
        table.insert(notes, { n = n, content = note.content })
        return pandoc.Link(pandoc.Superscript(tostring(n)), "#fn" .. n, "",
          pandoc.Attr("fnref" .. n, { "footnote-ref" }, { role = "doc-noteref" }))
      end,
    })
    blocks:insert(block)
    for _, note in ipairs(notes) do
      local content = note.content:clone()
      local number = { pandoc.Str(note.n .. "."), pandoc.Space() }
      local first = content[1]
      if first and (first.t == "Para" or first.t == "Plain") then
        first.content = pandoc.Inlines(number) .. first.content
      else
        content:insert(1, pandoc.Plain(number))
      end
      blocks:insert(pandoc.Div(content,
        pandoc.Attr("fn" .. note.n, { "column-margin", "footnote" }, { role = "doc-footnote" })))
    end
  end
  doc.blocks = blocks
  return doc
end

-- Site navigation. Quarto builds its navbar and page footer only with
-- Bootstrap, and doesn't pass the website settings to filters, so read them
-- from _quarto.yml (and the active profiles' files) and write plain HTML.

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

-- A link target relative to the project root, made relative to this page.
-- Quarto turns links to .qmd files into links to .html files later.
local function href(target)
  if target:match("^%a[%w+.-]*:") or target:match("^#") then return target end
  return (quarto.project.offset or ".") .. "/" .. target:gsub("^/", "")
end

-- The website settings, or nil outside a website project.
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

-- A page's title, for navbar items that only name a file.
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
  return '<header class="site-header"><nav class="site-nav" aria-label="Site">' .. brand
    .. nav_list(navbar.left, "nav-left", current) .. nav_list(navbar.right, "nav-right", current)
    .. "</nav></header>"
end

local function footer_part(value)
  local kind = pandoc.utils.type(value)
  if kind == "List" then
    local out = {}
    for _, item in ipairs(value) do
      local a = nav_link(item, nil)
      if a then table.insert(out, a) end
    end
    return table.concat(out, " · ")
  elseif kind == "Inlines" or kind == "Blocks" then
    local blocks = kind == "Inlines" and pandoc.Blocks({ pandoc.Plain(value) }) or value
    blocks = blocks:walk({ Link = function(l) l.target = href(l.target) return l end })
    return pandoc.write(pandoc.Pandoc(blocks), "html")
  end
  return ""
end

local function footer_html(site)
  local footer = site["page-footer"]
  if not footer then return "" end
  local parts = pandoc.utils.type(footer) == "table" and { footer.left, footer.center, footer.right } or { footer }
  local html = {}
  for i = 1, 3 do
    local part = parts[i] and footer_part(parts[i]) or ""
    if part ~= "" then table.insert(html, "<div>" .. part .. "</div>") end
  end
  return #html > 0 and ('<footer class="site-footer">' .. table.concat(html) .. "</footer>") or ""
end

-- Wrap the page in <main class="content" id="quarto-content">, between the
-- site's navbar and footer. Quarto copies a post's full text into RSS feeds
-- from main.content, and appends listings to #quarto-content.
local function page(doc)
  local site = website()
  local header = site and nav_html(site) or ""
  local footer = site and footer_html(site) or ""
  quarto.doc.include_text("before-body", header .. '<main class="content" id="quarto-content">')
  quarto.doc.include_text("after-body", "</main>" .. footer)
  if param("reference-location", "document") == "margin" then
    return margin_footnotes(doc)
  end
end

return {
  { Callout = callout, Tabset = tabset },
  { Pandoc = page },
}
