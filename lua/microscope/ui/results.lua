local window = require("microscope.ui.window")
local events = require("microscope.events")
local results = {}

local function build_parser(parsers, idx)
  idx = idx or #parsers
  if idx == 0 then
    return function(data, _)
      return { text = data }
    end
  end

  local prev_parser = build_parser(parsers, idx - 1)

  return function(data, request)
    return parsers[idx](prev_parser(data, request), request)
  end
end

local function get_focused(self)
  if not self:get_cursor() then
    return
  end

  local cursor = self:get_cursor()[1]
  if self.data and self.data[cursor] then
    return self.data[cursor]
  end
end

local function on_empty_results_retrieved(self)
  self:clear()
end

local function on_new_request(self, request)
  self.data = {}
  self.selected_data = {}
  self.results = {}
  self.request = request
end

local function on_results_retrieved(self, list)
  self.results = list

  self:write(list)
  self:set_cursor({ 1, 0 })
end

local function on_new_opts(self, opts)
  self.parser = build_parser(opts.parsers or {})
end

local function on_close(self)
  self.data = {}
  self.selected_data = {}
  self.results = {}
  self.request = nil
  self:close()
end

function results:show(layout, focus)
  window.show(self, layout, focus)

  self:parse()

  self:set_win_opt("wrap", false)
  self:set_win_opt("scrolloff", 10000)
  self:set_win_opt("cursorline", true)
end

function results:select()
  local cursor = self:get_cursor()

  if not cursor then
    return
  end

  local row = cursor[1]
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

function results:parse()
  if #self.results == 0 then
    return
  end

  local height = self.layout and self.layout.height or 10
  local min = math.max(self:get_cursor()[1] - height - 1, 1)
  local max = math.min(self:get_cursor()[1] + height + 1, self:line_count())

  for idx = min, max, 1 do
    if not self.data[idx] then
      self.data[idx] = self.parser(self.results[idx], self.request)
      self:write({ self.data[idx].text }, idx - 1, idx)
      for _, hl in pairs(self.data[idx].highlights or {}) do
        self:set_buf_hl(hl.color, idx, hl.from, hl.to)
      end
    end
  end
end

function results:selected()
  local selected = vim.tbl_values(self.selected_data)
  local focused = get_focused(self)

  if #selected == 0 and focused then
    return { focused }
  elseif #selected > 0 then
    return selected
  else
    return {}
  end
end

function results:open(metadata)
  local selected = self:selected()

  if #selected > 0 then
    events.fire(events.event.results_opened, { selected = selected, metadata = metadata })
  end

  self.selected_data = {}
end

function results:set_cursor(cursor)
  window.set_cursor(self, cursor)
  self:parse()
  local focused = get_focused(self)
  if focused then
    events.fire(events.event.result_focused, focused, 100)
  end
end

function results:raw_results()
  return self.results
end

function results.new()
  local v = window.new(results)

  v.data = {}
  v.selected_data = {}
  v.results = {}
  v.parser = build_parser({})
  v:set_buf_opt("modifiable", false)

  events.on(v, events.event.empty_results_retrieved, on_empty_results_retrieved)
  events.on(v, events.event.results_retrieved, on_results_retrieved)
  events.on(v, events.event.new_request, on_new_request)
  events.on(v, events.event.microscope_closed, on_close)
  events.on(v, events.event.new_opts, on_new_opts)
  events.native(v, events.event.cursor_moved, function()
    if v.win then
      local cursor = vim.api.nvim_win_get_cursor(v.win)
      local win_cursor = v:get_cursor()

      if win_cursor and cursor[1] ~= win_cursor[1] then
        v:set_cursor(cursor)
      end
    end
  end)

  return v
end

return results
