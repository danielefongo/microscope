local ansiline = require("microscope.utils.ansiline")
local window = require("microscope.window")
local events = require("microscope.events")
local constants = require("microscope.constants")
local preview = {}
setmetatable(preview, window)

local function on_close(self)
  events.clear_module(self)
  self.data = nil
  self:close()
end

local function on_result_focused(self, data)
  self.data = data
  self:set_buf_opt("syntax", "off")
  self.preview_fun(data, self)
end

local function on_empty_results_retrieved(self)
  self.data = nil
  if self.term then
    vim.fn.chanclose(self.term)
  end
  self:clear()
end

local function on_layout_updated(self, layout)
  self.layout = layout.preview
  self:show(self.layout)

  if self.data then
    on_result_focused(self, self.data)
  end

  self:set_win_opt("cursorline", true)
end

function preview:write_term(lines)
  self:clear()
  self.term = vim.api.nvim_open_term(self:get_buf(), {})
  self:set_buf_opt("modifiable", true)

  for _, i in pairs(lines) do
    vim.api.nvim_chan_send(self.term, ansiline(i, self.layout.width))
  end

  vim.defer_fn(function()
    vim.api.nvim_win_set_cursor(self.win, { 1, 0 })
  end, 10)
end

function preview.new(preview_fun)
  local v = setmetatable(preview, { __index = window })

  v.preview_fun = preview_fun
  v:new_buf()

  events.on(v, constants.event.result_focused, on_result_focused)
  events.on(v, constants.event.empty_results_retrieved, on_empty_results_retrieved)
  events.on(v, constants.event.layout_updated, on_layout_updated)
  events.on(v, constants.event.microscope_closed, on_close)

  return v
end

return preview
