local DOWN = 1
local UP = 2
local M = {}

local function rotate(results, dir)
  local counts = vim.api.nvim_buf_line_count(results.buf)
  local cursor = vim.api.nvim_win_get_cursor(results.win)[1]
  if dir == DOWN then
    vim.api.nvim_win_set_cursor(results.win, { (cursor - 1 + 1) % counts + 1, 0 })
  elseif dir == UP then
    vim.api.nvim_win_set_cursor(results.win, { (cursor - 1 - 1) % counts + 1, 0 })
  end
end

function M.previous(view)
  rotate(view.results, UP)
end

function M.next(view)
  rotate(view.results, DOWN)
end

function M.open(view)
  local results = view.results
  local input = view.input
  local file = results:selected()
  vim.api.nvim_buf_delete(results.buf, { force = true })
  vim.api.nvim_buf_delete(input.buf, { force = true })
  results:open(file)
end

return M
