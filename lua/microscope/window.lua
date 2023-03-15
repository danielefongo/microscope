local window = {}

function window:set_buf_hl(color, line, from, to)
  vim.api.nvim_buf_add_highlight(self.buf, 0, color, line - 1, from - 1, to)
end

function window:set_win_opt(key, value)
  vim.api.nvim_win_set_option(self.win, key, value)
end

function window:set_buf_opt(key, value)
  vim.api.nvim_buf_set_option(self.buf, key, value)
end

function window:get_win()
  return self.win
end

function window:new_buf()
  self.buf = vim.api.nvim_create_buf(false, true)
end

function window:get_buf()
  return self.buf
end

function window:set_buf(buf)
  vim.api.nvim_win_set_buf(self.win, buf)
end

function window:set_cursor(cursor)
  local counts = vim.api.nvim_buf_line_count(self.buf)
  local row = math.min(math.max(cursor[1], 1), counts)
  local col = math.max(cursor[2], 0)
  vim.api.nvim_win_set_cursor(self.win, { row, col })
end

function window:get_cursor()
  return vim.api.nvim_win_get_cursor(self.win)
end

function window:clear()
  self:write({})
end

function window:write(lines, from, to)
  from = from or 0
  to = to or -1
  vim.api.nvim_buf_set_lines(self.buf, from, to, true, lines)
end

function window:read(from, to)
  return vim.api.nvim_buf_get_lines(self.buf, from, to, false)
end

function window:show(opts, enter)
  self.layout = opts

  if not self.win then
    self.win = vim.api.nvim_open_win(self.buf, enter or false, self.layout)
  else
    vim.api.nvim_win_set_config(self.win, self.layout)
  end
end

function window:close()
  vim.api.nvim_win_set_buf(self.win, self.buf)
  vim.api.nvim_buf_delete(self.buf, { force = true })
  self.win = nil
  self.buf = nil
end

function window.new()
  local w = setmetatable({ keys = {} }, window)

  return w
end

return window
