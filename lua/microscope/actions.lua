local DOWN = 1
local UP = 2
local actions = {}

local function rotate(microscope, dir)
  local results = microscope.results
  local counts = vim.api.nvim_buf_line_count(results.buf)
  local cursor = vim.api.nvim_win_get_cursor(results.win)[1]
  if dir == DOWN then
    vim.api.nvim_win_set_cursor(results.win, { (cursor - 1 + 1) % counts + 1, 0 })
  elseif dir == UP then
    vim.api.nvim_win_set_cursor(results.win, { (cursor - 1 - 1) % counts + 1, 0 })
  end
  microscope:show_preview()
end

local function scroll(microscope, dir, amount)
  local preview = microscope.preview
  local counts = vim.api.nvim_buf_line_count(preview.buf)
  local cursor = vim.api.nvim_win_get_cursor(preview.win)[1]
  if dir == DOWN then
    vim.api.nvim_win_set_cursor(preview.win, { math.min(cursor + amount, counts), 0 })
  elseif dir == UP then
    vim.api.nvim_win_set_cursor(preview.win, { math.max(cursor - amount, 1), 0 })
  end
end

function actions.previous(microscope)
  rotate(microscope, UP)
end

function actions.next(microscope)
  rotate(microscope, DOWN)
end

function actions.scroll_down(microscope)
  scroll(microscope, DOWN, 10)
end

function actions.scroll_up(microscope)
  scroll(microscope, UP, 10)
end

function actions.open(microscope)
  local results = microscope.results
  local data = results:selected()
  results:open(data)
  actions.close(microscope)
end

function actions.close(microscope)
  microscope:close()
end

return actions
