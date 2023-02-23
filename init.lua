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

local function open_file(data)
  vim.cmd("e " .. data.text)
  if data.row and data.col then
    local win = vim.api.nvim_get_current_win()
    local cursor = { data.row, data.col }
    vim.api.nvim_win_set_cursor(win, cursor)
  end
end

local function open_buffer(data)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, data.buffer)
end

function _G.yaff_vimgrep()
  view:show(function(text, cb)
    return stream.chain({
      lists.vimgrep(text),
      lists.head(10),
    }, cb)
  end, open_file)
end

function _G.yaff_files()
  view:show(function(text, cb)
    return stream.chain({
      lists.rg(),
      lists.fzf(text),
      lists.head(10),
    }, cb)
  end, open_file)
end

function _G.yaff_buffers()
  view:show(function(text, cb)
    return stream.chain({
      lists.buffers(),
      lists.fzf(text),
    }, cb)
  end, open_buffer)
end
