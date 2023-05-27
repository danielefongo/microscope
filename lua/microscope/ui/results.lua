local window = require("microscope.ui.window")
local events = require("microscope.events")
local results = {}

local function get_focused(self)
  local cursor = self:get_cursor()[1]
  if self.data and self.data[cursor] then
    return self.data[cursor]
  end
end

local function on_input_changed(self)
  self.data = {}
  self.selected_data = {}
end

local function on_empty_results_retrieved(self)
  self:clear()
end

local function on_results_retrieved(self, data)
  self.data = data

  local list = vim.tbl_map(function(el)
    return el.text
  end, self.data)

  self:write(list)
  self:set_cursor({ 1, 0 })

  for row = 1, vim.api.nvim_buf_line_count(self.buf), 1 do
    for _, hl in pairs(data[row].highlights or {}) do
      self:set_buf_hl(hl.color, row, hl.from, hl.to)
    end
  end
end

local function on_close(self)
  self.data = {}
  self.selected_data = {}
  self:close()
end

function results:show(build)
  window.show(self, build)

  self:set_win_opt("wrap", false)
  self:set_win_opt("scrolloff", 10000)
  self:set_win_opt("cursorline", true)
end

function results:select()
  if not self.win then
    return
  end
  local row = self:get_cursor()[1]
  local element = self.data[row]

  if element then
    if not self.selected_data[row] then
      self:write({ "> " .. element.text }, row - 1, row)
      self.selected_data[row] = element
      for _, hl in pairs(self.data[row].highlights or {}) do
        self:set_buf_hl(hl.color, row, hl.from + 2, hl.to + 2)
      end
    else
      self:write({ element.text }, row - 1, row)
      self.selected_data[row] = nil
      for _, hl in pairs(self.data[row].highlights or {}) do
        self:set_buf_hl(hl.color, row, hl.from, hl.to)
      end
    end
  end
end

function results:selected()
  if #self.selected_data == 0 then
    return { get_focused(self) }
  else
    return vim.tbl_values(self.selected_data)
  end
end

function results:open(metadata)
  events.fire(events.event.results_opened, { selected = self:selected(), metadata = metadata })

  self.selected_data = {}
end

function results:set_cursor(cursor)
  window.set_cursor(self, cursor)
  local focused = get_focused(self)
  if focused then
    events.fire(events.event.result_focused, focused, 100)
  end
end

function results.new()
  local v = window.new(results)

  v.data = {}
  v.selected_data = {}

  events.on(v, events.event.input_changed, on_input_changed)
  events.on(v, events.event.empty_results_retrieved, on_empty_results_retrieved)
  events.on(v, events.event.results_retrieved, on_results_retrieved)
  events.on(v, events.event.microscope_closed, on_close)

  return v
end

return results
