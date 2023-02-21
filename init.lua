local actions = require("yaff.actions")
local lists = require("yaff.lists")
local stream = require("yaff.stream")
local view = require("yaff.view")

function _G.n_menu()
  local viewz = view.new({
    size = {
      width = 50,
      height = 10,
    },
    bindings = {
      ["<c-j>"] = actions.next,
      ["<c-k>"] = actions.previous,
      ["<Tab>"] = actions.open,
    },
    chain = function(text, cb)
      return stream.chain({
        lists.rg(),
        lists.fzf(text),
        lists.head(10),
      }, cb)
    end,
  })
  viewz:show()
end
