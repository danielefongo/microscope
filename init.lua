local actions = require("yaff.actions")
local lists = require("yaff.lists")
local stream = require("yaff.stream")

local view = require("yaff.view").new({
  size = {
    width = 50,
    height = 10,
  },
  bindings = {
    ["<c-j>"] = actions.next,
    ["<c-k>"] = actions.previous,
    ["<Tab>"] = actions.open,
  },
})

function _G.yaff_files()
  view:show(function(text, cb)
    return stream.chain({
      lists.rg(),
      lists.fzf(text),
    }, cb)
  end)
end
