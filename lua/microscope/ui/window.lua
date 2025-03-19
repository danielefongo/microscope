local events = require("microscope.events")
local window = {}

function window:clear_buf_hls()
  if not self.buf then
    return
  end
  vim.api.nvim_buf_clear_namespace(self.buf, self.namespace, 0, -1)
end

function window:set_buf_hls(highlights)
  if not self.buf then
    return
  end
  for row, row_highlights in pairs(highlights) do
    for _, hl in ipairs(row_highlights) do
      local line = row - 1
      vim.api.nvim_buf_add_highlight(self.buf, self.namespace, hl.color, line, hl.from - 1, hl.to)
    end
  end
end

--- @deprecated
function window:set_buf_hl(color, line, from, to)
  self:set_buf_hls({ [line] = { { color = color, from = from, to = to } } })
end

function window:get_win_opt(key)
  if self.win then
    return vim.api.nvim_win_get_option(self.win, key)
  end
end

function window:set_win_opt(key, value)
  if self.win then
    vim.api.nvim_win_set_option(self.win, key, value)
  end
end

function window:get_buf_opt(key)
  if self.buf then
    return vim.api.nvim_buf_get_option(self.buf, key)
  end
end

function window:set_buf_opt(key, value)
  if self.buf then
    vim.api.nvim_buf_set_option(self.buf, key, value)
  end
end

function window:get_win()
  return self.win
end

function window:new_buf()
  self.buf = vim.api.nvim_create_buf(false, true)
  self.buf = self.buf
end

function window:get_buf()
  return self.buf
end

function window:set_cursor(cursor)
  local counts = self:line_count()
  local row = math.min(math.max(cursor[1], 1), counts)

  local row_chars = self:read(row - 1, row)[1]
  local col = math.min(math.max(cursor[2], 0), math.max(#row_chars - 1, 0))

  self.cursor = { row, col }

  if self.win then
    vim.api.nvim_win_set_cursor(self.win, self.cursor)
  end
end

function window:get_cursor()
  return self.cursor
end

function window:line_count()
  return vim.api.nvim_buf_line_count(self.buf)
end

function window:clear()
  self:set_cursor({ 1, 0 })
  self:write({})
end

function window:write(lines, from, to)
  if not self.buf then
    return
  end

  local is_modifiable = self:get_buf_opt("modifiable")

  self:set_buf_opt("modifiable", true)
  from = from or 0
  to = to or -1
  vim.api.nvim_buf_set_lines(self.buf, from, to, true, lines)
  self:set_buf_opt("modifiable", is_modifiable)
end

function window:read(from, to)
  if not self.buf then
    return
  end

  from = from or 0
  to = to or -1
  return vim.api.nvim_buf_get_lines(self.buf, from, to, true)
end

function window:show(layout, focus)
  self.layout = layout or self.layout
  self.focus = focus
  if not layout then
    return self:hide()
  end

  layout = vim.tbl_deep_extend("force", layout, self.title or {})

  if not self.win then
    self.win = vim.api.nvim_open_win(self.buf, false, layout)
  else
    vim.api.nvim_win_set_config(self.win, layout)
    vim.api.nvim_win_set_buf(self.win, self.buf)
  end

  if focus then
    vim.api.nvim_set_current_win(self.win)
    if self.cursor then
      window.set_cursor(self, self.cursor)
    end
  end
end

function window:set_title(title, pos)
  self.title = {
    title = title,
    title_pos = pos,
  }
  if self.win then
    self:show(self.layout, self.focus)
  end
end

function window:get_title()
  return self.title
end

function window:hide()
  if self.win then
    vim.api.nvim_win_hide(self.win)
    self.win = nil
  end
end

function window:close()
  self.events:clear_module(self)
  self.layout = nil
  self.cursor = nil
  if self.win then
    pcall(function()
      vim.api.nvim_win_set_buf(self.win, self.buf)
    end)
    vim.api.nvim_buf_delete(self.buf, { force = true })
    self.win = nil
  end
  self.buf = nil
end

function window.new(child, events_instance, name)
  local w = setmetatable(child or {}, { __index = window })

  w.namespace = vim.api.nvim_create_namespace("MicroscopeHighlight" .. (name or "Window"))
  w.events = events_instance
  w:new_buf()
  w:set_buf_opt("bufhidden", "hide")

  w.events:native(w, events.event.buf_leave, function()
    if w.win then
      w.events:fire(events.event.win_leave)
    end
  end, { buffer = w.buf })

  return w
end

return window
