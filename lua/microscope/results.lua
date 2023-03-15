local window = require("microscope.window")
local events = require("microscope.events")
local constants = require("microscope.constants")
local highlight = require("microscope.highlight")
local results = {}
setmetatable(results, window)

local function get_focused(self)
  local cursor = self:get_cursor()[1]
  if self.data and self.data[cursor] then
    return self.data[cursor]
  end
end

local function on_layout_updated(self, layout)
  self:show(layout.results)

  self:set_buf_opt("buftype", "prompt")
  self:set_win_opt("cursorline", true)
end

local function on_input_changed(self)
  self.data = {}
  self.selected_data = {}

  self:clear()
end

local function on_results_retrieved(self, data)
  self.data = data

  local list = {}
  for _, el in pairs(self.data) do
    table.insert(list, el.text)
  end

  self:write(list)
  self:set_cursor({ 1, 0 })

  for row = 1, vim.api.nvim_buf_line_count(self.buf), 1 do
    for _, hl in pairs(data[row].highlights or {}) do
      highlight.set_buf_hl(self.buf, hl.color, row, hl.from, hl.to)
    end
  end
end

local function on_close(self)
  self.data = {}
  self.selected_data = {}

  events.clear_module(self)
  self:close()
end

function results:select()
  local row = self:get_cursor()[1]
  local element = self.data[row]

  if element then
    if not self.selected_data[row] then
      self:write({ "> " .. element.text }, row - 1, row)
      self.selected_data[row] = element
      for _, hl in pairs(self.data[row].highlights or {}) do
        highlight.set_buf_hl(self.buf, hl.color, row, hl.from + 2, hl.to + 2)
      end
    else
      self:write({ element.text }, row - 1, row)
      self.selected_data[row] = nil
      for _, hl in pairs(self.data[row].highlights or {}) do
        highlight.set_buf_hl(self.buf, hl.color, row, hl.from, hl.to)
      end
    end
  end
end

function results:open()
  local to_be_open = {}

  if #self.selected_data == 0 then
    table.insert(to_be_open, get_focused(self))
  end

  for _, value in pairs(self.selected_data) do
    table.insert(to_be_open, value)
  end

  events.fire(constants.event.results_opened, to_be_open)

  self.selected_data = {}
end

function results:set_cursor(cursor)
  window.set_cursor(self, cursor)
  local focused = get_focused(self)
  if focused then
    events.fire(constants.event.result_focused, focused)
  end
end

function results.new()
  local v = setmetatable(results, { __index = window })

  v:new_buf()

  events.on(v, constants.event.layout_updated, on_layout_updated)
  events.on(v, constants.event.input_changed, on_input_changed)
  events.on(v, constants.event.results_retrieved, on_results_retrieved)
  events.on(v, constants.event.microscope_closed, on_close)

  return v
end

return results
