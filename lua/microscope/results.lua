local window = require("microscope.window")
local events = require("microscope.events")
local constants = require("microscope.constants")
local results = {}
setmetatable(results, window)

local function get_focused(self)
  local cursor = self:get_cursor()[1]
  local line = self:read(cursor - 1, cursor)[1]
  if line and line ~= "" then
    return self.parser(line)
  end
end

local function on_layout_updated(self, layout)
  self:show(layout.results)

  self:set_buf_opt("buftype", "prompt")
  self:set_win_opt("cursorline", true)
end

local function on_input_changed(self)
  self.selected_lines = {}
  self:clear()
end

local function on_results_retrieved(self, data)
  self.parser = data.parser

  self:write(data.list)
  self:set_cursor({ 1, 0 })
end

local function on_close(self)
  events.clear_module(self)
  self:close()
end

function results:select()
  local row = self:get_cursor()[1]
  local line = self:read(row - 1, row)[1]

  if line then
    if not self.selected_lines[row] then
      self:write({ "> " .. line }, row - 1, row)
      self.selected_lines[row] = line
    else
      self:write({ self.selected_lines[row] }, row - 1, row)
      self.selected_lines[row] = nil
    end
  end
end

function results:open()
  local to_be_open = {}

  if #self.selected_lines == 0 then
    table.insert(to_be_open, get_focused(self))
  end

  for _, value in pairs(self.selected_lines) do
    table.insert(to_be_open, self.parser(value))
  end

  events.fire(constants.event.results_opened, to_be_open)

  self.selected_lines = {}
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
