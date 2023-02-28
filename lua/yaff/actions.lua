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

function M.previous(yaff)
  rotate(yaff.results, UP)
end

function M.next(yaff)
  rotate(yaff.results, DOWN)
end

function M.open(yaff)
  local results = yaff.results
  local file = results:selected()
  results:open(file)
  M.close(yaff)
end

function M.close(yaff)
  yaff:close()
end

return M
