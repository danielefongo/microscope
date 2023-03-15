local fzy = require("microscope.utils.fzy")
local highlight = require("microscope.highlight")
local constants = require("microscope.constants")
local lists = {}

function lists.fzf(text)
  return {
    command = "fzf",
    args = { "--filter", text },
    parser = function(data)
      local hl = highlight.new(data.highlights or {}, data.text)

      local words = vim.split(text, " ", { trimempty = true })

      for _, word in pairs(words) do
        for _, position in pairs(fzy.positions(word, data.text, false)) do
          hl:hl(constants.color.match, position, position)
        end
      end
      data.highlights = hl:get_highlights()

      return data
    end,
  }
end

function lists.head(lines)
  return {
    command = "head",
    args = { "-n", lines },
  }
end

return lists
