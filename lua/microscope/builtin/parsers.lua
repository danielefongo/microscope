local highlight = require("microscope.api.highlight")
local fzy = require("microscope.utils.fzy")

local parsers = {}

function parsers.fuzzy(data, request)
  local hl = highlight.new(data.highlights or {}, data.text)

  local words = vim.split(request.text, " ", { trimempty = true })

  for _, word in pairs(words) do
    for _, position in pairs(fzy.positions(word, data.text, false)) do
      hl:hl(highlight.color.match, position, position)
    end
  end

  data.highlights = hl:get_highlights()

  return data
end

return parsers
