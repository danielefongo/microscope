local constants = require("microscope.constants")
local preview = {}
preview.__index = preview

function preview:close()
  vim.api.nvim_win_set_buf(self.win, self.buf)
  vim.api.nvim_buf_delete(self.buf, { force = true })
end

function preview:show(data)
  self.preview_fun(data, self.win, self.buf)
end

function preview:clear()
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, {})
end

function preview:scroll(dir, amount)
  local counts = vim.api.nvim_buf_line_count(self.buf)
  local cursor = vim.api.nvim_win_get_cursor(self.win)[1]
  if dir == constants.DOWN then
    vim.api.nvim_win_set_cursor(self.win, { math.min(cursor + amount, counts), 0 })
  elseif dir == constants.UP then
    vim.api.nvim_win_set_cursor(self.win, { math.max(cursor - amount, 1), 0 })
  end
end

function preview:update(opts)
  vim.api.nvim_win_set_config(self.win, opts)

  vim.api.nvim_buf_set_option(self.buf, "buftype", "prompt")
  vim.api.nvim_win_set_option(self.win, "cursorline", true)
end

function preview.new(opts, preview_fun)
  local v = setmetatable({ keys = {} }, preview)

  v.preview_fun = preview_fun
  v.buf = vim.api.nvim_create_buf(false, true)
  v.win = vim.api.nvim_open_win(v.buf, true, opts)

  v:update(opts)

  return v
end

return preview
