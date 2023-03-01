local results = {}
results.__index = results

function results:selected()
  local cursor = vim.api.nvim_win_get_cursor(self.win)[1]
  local line = vim.api.nvim_buf_get_lines(self.buf, cursor - 1, cursor, false)[1]
  if line and line ~= "" then
    return self.parser(line)
  end
end

function results:close()
  vim.api.nvim_buf_delete(self.buf, { force = true })
end

function results:open(file)
  self.on_open(file)
end

function results:on_new()
  vim.schedule(function()
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, {})
  end)
end

function results:on_data(list, parser)
  self.parser = parser

  vim.schedule(function()
    vim.api.nvim_win_set_cursor(self.win, { 1, 0 })
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, list)
  end)
end

function results:update(opts)
  vim.api.nvim_win_set_config(self.win, opts)

  vim.api.nvim_buf_set_option(self.buf, "buftype", "prompt")
  vim.api.nvim_win_set_option(self.win, "cursorline", true)
end

function results.new(opts, on_open)
  local v = setmetatable({ keys = {} }, results)

  v.on_open = on_open
  v.buf = vim.api.nvim_create_buf(false, true)
  v.win = vim.api.nvim_open_win(v.buf, true, opts)

  v:update(opts)

  return v
end

return results
