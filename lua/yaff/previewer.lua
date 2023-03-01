local previewer = {}
previewer.__index = previewer

function previewer:close()
  vim.api.nvim_win_set_buf(self.win, self.buf)
  vim.api.nvim_buf_delete(self.buf, { force = true })
end

function previewer:show(data)
  self.preview_fun(data, self.win, self.buf)
end

function previewer.new(opts, preview_fun)
  local v = setmetatable({ keys = {} }, previewer)

  v.preview_fun = preview_fun
  v.buf = vim.api.nvim_create_buf(false, true)
  v.win = vim.api.nvim_open_win(v.buf, true, opts)

  vim.api.nvim_buf_set_option(v.buf, "buftype", "prompt")
  vim.api.nvim_win_set_option(v.win, "cursorline", true)

  return v
end

return previewer
