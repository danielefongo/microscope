local stream = require("microscope.stream")
local files_lists = require("microscope.files.lists")
local lists = require("microscope.lists")
local highlight = require("microscope.files.highlight")

local files = {}

files.max_size = 2 ^ 16

local function exists(path)
  local file = vim.loop.fs_open(path, "r", 438)
  if file == nil then
    return false
  end
  vim.loop.fs_close(file)
  return true
end

local function too_big(path)
  local file = vim.loop.fs_open(path, "r", 438)
  local file_size = vim.loop.fs_fstat(file).size
  vim.loop.fs_close(file)
  return file_size > files.max_size
end

local function is_binary(path)
  local handle = io.popen(string.format("file -n -b --mime-encoding '%s'", path))
  if not handle then
    return false
  end
  local binary_file = handle:read("*a"):match("binary")

  handle:close()
  return binary_file
end

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

  if not exists(data.text) then
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "Not existing" })
    return
  end

  if is_binary(data.text) then
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "Binary" })
    return
  end

  if too_big(data.text) then
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "Too big" })
    return
  end

  if files.stream then
    files.stream:stop()
  end

  files.stream = stream.chain({ files_lists.cat(data.text) }, function(lines)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
    highlight(data.text, buf)
    vim.api.nvim_win_set_cursor(win, cursor)
  end)

  files.stream:start()
end

files.lists = require("microscope.files.lists")

return files
