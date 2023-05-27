local ansiline = require("microscope.utils.ansiline")
local window = require("microscope.ui.window")
local events = require("microscope.events")
local preview = {}

local function on_close(self)
  self.data = nil
  self:close()
end

local function on_result_focused(self, data)
  self.term_lines = nil
  self.data = data

  self:set_buf_opt("syntax", "off")
  self.preview_fun(data, self)
end

local function on_empty_results_retrieved(self)
  self.data = nil
  self:clear()
end

function preview:show(build, focus)
  window.show(self, build, focus)

  if self.term_lines then
    self:write_term(self.term_lines)
  end

  self:set_win_opt("cursorline", true)
  self:set_win_opt("wrap", true)
  self:set_win_opt("scrolloff", 10000)
end

function preview:write_term(lines)
  self:clear()
  self.term = vim.api.nvim_open_term(self:get_buf(), {})
  self:set_buf_opt("modifiable", true)

  for _, i in pairs(lines) do
    vim.api.nvim_chan_send(self.term, ansiline(i, self.layout.width))
  end

  vim.defer_fn(function()
    self:set_cursor({ 1, 0 })
  end, 10)
end

function preview.new(preview_fun)
  local v = window.new(preview)

  v.preview_fun = preview_fun

  events.on(v, events.event.result_focused, on_result_focused)
  events.on(v, events.event.empty_results_retrieved, on_empty_results_retrieved)
  events.on(v, events.event.microscope_closed, on_close)

  return v
end

return preview
