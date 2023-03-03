local stream = require("microscope.stream")
local files_lists = require("microscope.files.lists")
local lists = require("microscope.lists")
local highlight = require("microscope.files.highlight")

local files = {}

function files.open(data, win, _)
  vim.cmd("e " .. data.text)
  if data.row and data.col then
    local cursor = { data.row, data.col }
    vim.api.nvim_win_set_cursor(win, cursor)
  end
end

function files.preview(data, win, buf)
  local cursor
  if data.col and data.row then
    cursor = { data.row, data.col }
  else
    cursor = { 1, 0 }
  end
  if files.stream then
    files.stream:stop()
  end
  files.stream = stream.chain({
    files_lists.cat(data.text),
    lists.head(5000),
  }, function(lines)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
    highlight(data.text, buf)
    vim.api.nvim_win_set_cursor(win, cursor)
  end)

  files.stream:start()
end

files.lists = require("microscope.files.lists")

return files
