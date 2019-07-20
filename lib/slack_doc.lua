
local pipe = pandoc.pipe
local stringify = (require "pandoc.utils").stringify

-- The global variable PANDOC_DOCUMENT contains the full AST of
-- the document which is going to be written. It can be used to
-- configure the writer.
local meta = PANDOC_DOCUMENT.meta

-- Chose the image format based on the value of the
-- `image_format` meta value.
local image_format = meta.image_format
  and stringify(meta.image_format)
  or "png"
local image_mime_type = ({
    jpeg = "image/jpeg",
    jpg = "image/jpeg",
    gif = "image/gif",
    png = "image/png",
    svg = "image/svg+xml",
  })[image_format]
  or error("unsupported image format `" .. img_format .. "`")

-- Character escaping
local function escape(s, in_attribute)
  -- return s:gsub("[<>&\"']",
  --   function(x)
  --     if x == '<' then
  --       return '&lt;'
  --     elseif x == '>' then
  --       return '&gt;'
  --     elseif x == '&' then
  --       return '&amp;'
  --     elseif x == '"' then
  --       return '&quot;'
  --     elseif x == "'" then
  --       return '&#39;'
  --     else
  --       return x
  --     end
  --   end)
  return s
end

-- Table to store footnotes, so they can be included at the end.
local notes = {}

-- Blocksep is used to separate block elements.
function Blocksep()
  return "\n\n"
end

-- This function is called once for the whole document. Parameters:
-- body is a string, metadata is a table, variables is a table.
-- This gives you a fragment.  You could use the metadata table to
-- fill variables in a custom lua template.  Or, pass `--template=...`
-- to pandoc, and pandoc will add do the template processing as
-- usual.
function Doc(body, metadata, variables)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add(body)
  if #notes > 0 then
    add(HorizontalRule())
    add(OrderedList(notes))
  end
  return table.concat(buffer,'\n')
end

function LeftTrim(s)
  return s:match( "^%s*(.+)" )
end

-- The functions that follow render corresponding pandoc elements.
-- s is always a string, attr is always a table of attributes, and
-- items is always an array of strings (the items in a list).
-- Comments indicate the types of other variables.

function Str(s)
  return escape(s)
end

function Space()
  return " "
end

function SoftBreak()
  return "\n"
end

function LineBreak()
  return "\n"
end

function Emph(s)
  return "_" .. s .. "_"
end

function Strong(s)
  return "*" .. s .. "*"
end

function Strikeout(s)
  return '~' .. s .. '~'
end

function Link(s, src, tit, attr)
  if s == src then
    return src
  end
  return Note("["..s.."]("..src..")")
end

function Image(s, src, tit, attr)
  return "![]("..src..")"
end

function Code(s, attr)
  return "`" .. s .. "`"
end


function Note(s)
  local num = #notes + 1
  b = string.gsub(s, '%[(.*)%]%((.*)%)', '`%1` : %2')
  table.insert(notes, b)

  return string.gsub(s, '%[(.*)%]%((.*)%)', '`<%1>').."#"..num.."`"
end

function Plain(s)
  return s
end

function Para(s)
  -- choosing to not add a linebreak here, as it tends to add too much
  -- whitespace
  return s
end

-- lev is an integer, the header level.
function Header(lev, s, attr)
  return "*" .. s  .. "*"
end

function BlockQuote(s)
  left_trim_s = LeftTrim(s)
  return ">  " .. string.gsub(left_trim_s, "\n", "\n>  ")
end

function HorizontalRule()
  return "------------------------"
end

function CodeBlock(s, attr)
  return '```\n' .. s .. '```'
end

function BulletList(items)
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "• " .. LeftTrim(item))
  end
  return table.concat(buffer, "\n")
end

function OrderedList(items)
  local buffer = {}
  for idx, item in pairs(items) do
    table.insert(buffer, idx ..". " .. LeftTrim(item))
  end
  return table.concat(buffer, "\n")
end

-- function DefinitionList(items)
--   local buffer = {}
--   for _,item in pairs(items) do
--     local k, v = next(item)
--     table.insert(buffer, "<dt>" .. k .. "</dt>\n<dd>" ..
--                    table.concat(v, "</dd>\n<dd>") .. "</dd>")
--   end
--   return "<dl>\n" .. table.concat(buffer, "\n") .. "\n</dl>"
-- end

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
function Table(caption, aligns, widths, headers, rows)
  return ":warning: *Tables not supported"
  -- local buffer = {}
  -- local function add(s)
  --   table.insert(buffer, s)
  -- end
  -- add("<table>")
  -- if caption ~= "" then
  --   add("<caption>" .. caption .. "</caption>")
  -- end
  -- if widths and widths[1] ~= 0 then
  --   for _, w in pairs(widths) do
  --     add('<col width="' .. string.format("%.0f%%", w * 100) .. '" />')
  --   end
  -- end
  -- local header_row = {}
  -- local empty_header = true
  -- for i, h in pairs(headers) do
  --   local align = html_align(aligns[i])
  --   table.insert(header_row,'<th align="' .. align .. '">' .. h .. '</th>')
  --   empty_header = empty_header and h == ""
  -- end
  -- if empty_header then
  --   head = ""
  -- else
  --   add('<tr class="header">')
  --   for _,h in pairs(header_row) do
  --     add(h)
  --   end
  --   add('</tr>')
  -- end
  -- local class = "even"
  -- for _, row in pairs(rows) do
  --   class = (class == "even" and "odd") or "even"
  --   add('<tr class="' .. class .. '">')
  --   for i,c in pairs(row) do
  --     add('<td align="' .. html_align(aligns[i]) .. '">' .. c .. '</td>')
  --   end
  --   add('</tr>')
  -- end
  -- add('</table>')
  -- return table.concat(buffer,'\n')
end

-- The following code will produce runtime warnings when you haven't defined
-- all of the functions you need for the custom writer, so it's useful
-- to include when you're working on a writer.
local meta = {}
meta.__index =
  function(_, key)
    io.stderr:write(string.format("WARNING: Undefined function '%s'\n",key))
    return function() return "" end
  end
setmetatable(_G, meta)

