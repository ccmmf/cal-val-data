-- README.md uses a GitHub style ```mermaid fence so the diagram renders on GitHub.
-- Quarto only draws {mermaid} cells, so emit the same element Quarto uses for them.
-- index.qmd carries one hidden {mermaid} cell so Quarto ships its bundled Mermaid library.
local function esc(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

function CodeBlock(el)
  if el.classes[1] == "mermaid" and FORMAT:match("html") then
    return pandoc.RawBlock("html",
      '<div class="cell"><div class="cell-output-display"><div><pre class="mermaid mermaid-js">' ..
      esc(el.text) .. '</pre></div></div></div>')
  end
end
