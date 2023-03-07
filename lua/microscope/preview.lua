local window = require("microscope.window")
local events = require("microscope.events")
local constants = require("microscope.constants")
local preview = {}
setmetatable(preview, window)

local function on_layout_updated(self, layout)
  self:show(layout.preview)

  self:set_buf_opt("buftype", "prompt")
  self:set_win_opt("cursorline", true)
end

local function on_close(self)
  events.clear_module(self)
  self:close()
end

local function on_result_focused(self, data)
  self:set_buf_opt("syntax", "off")
  self.preview_fun(data, self)
end

local function on_empty_results_retrieved(self)
  self:clear()
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
