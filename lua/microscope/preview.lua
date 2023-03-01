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
