local results = {}
results.__index = results

function results:selected()
  local cursor = vim.api.nvim_win_get_cursor(self.win)[1]
  return vim.api.nvim_buf_get_lines(self.buf, cursor - 1, cursor, false)[1]
end

function results:on_new()
  vim.schedule(function()
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, {})
  end)
end

function results:on_data(list)
  vim.schedule(function()
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, list)
  end)
end

function results.new(opts)
  local v = setmetatable({ keys = {} }, results)

  v.buf = vim.api.nvim_create_buf(false, true)
  v.win = vim.api.nvim_open_win(v.buf, true, opts)

  vim.api.nvim_buf_set_option(v.buf, "buftype", "prompt")
  vim.api.nvim_win_set_option(v.win, "cursorline", true)

  return v
end

return results
