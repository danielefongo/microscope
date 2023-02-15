local DOWN = 1
local UP = 2
local M = {}

local function rotate(opts, dir)
  local counts = vim.api.nvim_buf_line_count(opts.buf)
  local cursor = vim.api.nvim_win_get_cursor(opts.win)[1]
  if dir == DOWN then
    vim.api.nvim_win_set_cursor(opts.win, { (cursor - 1 + 1) % counts + 1, 0 })
  elseif dir == UP then
    vim.api.nvim_win_set_cursor(opts.win, { (cursor - 1 - 1) % counts + 1, 0 })
  end
end

function M.previous(opts)
  rotate(opts, UP)
end

function M.next(opts)
  rotate(opts, DOWN)
end

function M.select(opts)
  local cursor = vim.api.nvim_win_get_cursor(opts.win)[1]
  vim.pretty_print(cursor)
  local line = vim.api.nvim_buf_get_lines(opts.buf, cursor - 1, cursor, false)[1]
  vim.api.nvim_buf_delete(opts.buf, {})
  vim.pretty_print(line)
end

return M
