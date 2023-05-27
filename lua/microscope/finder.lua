local layouts = require("microscope.builtin.layouts")
local events = require("microscope.events")
local error = require("microscope.api.error")
local scope = require("microscope.api.scope")
local preview = require("microscope.ui.preview")
local results = require("microscope.ui.results")
local input = require("microscope.ui.input")

local finder = {}
finder.__index = finder

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

function finder:bind_action(fun)
  return function()
    pcall(fun, self)
  end
end

function finder:close()
  events.clear_module(self)

  local cursor = vim.api.nvim_win_get_cursor(self.old_win)
  vim.api.nvim_set_current_win(self.old_win)
  vim.api.nvim_set_current_buf(self.old_buf)
  vim.api.nvim_win_set_cursor(self.old_win, { cursor[1], cursor[2] + 1 })

  events.fire(events.event.microscope_closed)
  self:stop_search()
  finder.instance = nil
end

function finder:close_with_err(error_data)
  if error_data.critical then
    self:close()
  end
  error.show(error_data)
end

function finder:open(data)
  self:close()
  for _, value in ipairs(data.selected) do
    self.open_fn(value, self.request, data.metadata)
  end
end

function finder:stop_search()
  self.find:stop()
end

function finder:search(text)
  if self.request and self.request.text == text then
    return
  end

  self:stop_search()
  self.request = {
    text = text,
    buf = self.old_buf,
    win = self.old_win,
  }
  self.find:search(self.request)
end

function finder:update()
  local build = self.layout_fn({
    finder_size = self.size,
    ui_size = vim.api.nvim_list_uis()[1],
    preview = self.has_preview,
    full_screen = self.full_screen,
  })

  events.clear(self, events.event.win_leave)
  self.preview:show(build.preview, build.input == nil)
  self.results:show(build.results, build.input == nil)
  self.input:show(build.input, true)
  events.native(self, events.event.win_leave, finder.close)
end

function finder:set_layout(new_layout)
  self.layout_fn = new_layout
  self:update()
end

function finder:toggle_full_screen()
  self.full_screen = not self.full_screen
  self:update()
end

function finder.new(opts)
  local self = setmetatable({}, finder)

  if finder.instance then
    return
  end
  finder.instance = self

  self.size = opts.size
  self.bindings = opts.bindings
  self.open_fn = opts.open or function() end
  self.has_preview = opts.preview ~= nil
  self.preview_fn = opts.preview or function(_, win)
    win:write({ "No preview function provided" })
  end
  self.layout_fn = opts.layout or layouts.default

  self.old_win = vim.api.nvim_get_current_win()
  self.old_buf = vim.api.nvim_get_current_buf()

  self.preview = preview.new(self.preview_fn)
  self.results = results.new()
  self.input = input.new()

  self.full_screen = false

  self.find = scope.new({
    lens = opts.lens,
    parser = build_parser(opts.parsers or {}),
    callback = function(list)
      if #list > 0 then
        events.fire(events.event.results_retrieved, list)
      else
        events.fire(events.event.empty_results_retrieved)
      end
    end,
  })

  events.on(self, events.event.results_opened, finder.open)
  events.on(self, events.event.input_changed, finder.search)
  events.on(self, events.event.error, finder.close_with_err)
  events.native(self, events.event.resize, finder.update)
  events.on(self, events.event.win_leave, finder.close)

  for lhs, action in pairs(self.bindings) do
    vim.keymap.set("i", lhs, self:bind_action(action), { buffer = self.input.buf })
    vim.keymap.set("n", lhs, self:bind_action(action), { buffer = self.results.buf })
    vim.keymap.set("n", lhs, self:bind_action(action), { buffer = self.preview.buf })
  end

  self:search("")
  self:update()

  return self
end

return finder
