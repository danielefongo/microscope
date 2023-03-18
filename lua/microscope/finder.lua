local constants = require("microscope.constants")
local error = require("microscope.error")
local preview = require("microscope.preview")
local results = require("microscope.results")
local events = require("microscope.events")
local input = require("microscope.input")
local stream = require("microscope.stream")
local shape = require("microscope.shape")
local finder = {}
finder.__index = finder
finder.finders = {}

function finder:bind_action(fun)
  return function()
    pcall(fun, self)
  end
end

function finder:close()
  events.clear_module(self)
  events.fire(constants.event.microscope_closed)
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
  vim.api.nvim_set_current_win(self.old_win)
  vim.api.nvim_set_current_buf(self.old_buf)
  for _, value in ipairs(data) do
    self.open_fn(value, self.old_win, self.old_buf)
  end
end

function finder:stop_search()
  if self.find then
    self.find:stop()
  end
end

function finder:search(text)
  self:stop_search()
  self.find = stream.chain(self.chain_fn(text, self.old_win, self.old_buf), function(list, parser)
    if #list > 0 then
      events.fire(constants.event.results_retrieved, vim.tbl_map(parser, list))
    else
      events.fire(constants.event.empty_results_retrieved)
    end
  end)
  self.find:start()
end

function finder:update()
  local layout
  if self.full_screen then
    layout = shape.generate(vim.api.nvim_list_uis()[1], self.preview_fn ~= nil)
  else
    layout = shape.generate(self.size, self.preview_fn ~= nil)
  end

  if layout then
    return events.fire(constants.event.layout_updated, layout)
  else
    error.critical("microscope: window too small to display")
  end
end

function finder:toggle_full_screen()
  self.full_screen = not self.full_screen
  self:update()
end

function finder.new(global_opts, opts)
  local self = setmetatable({ keys = {} }, finder)

  if finder.instance then
    return
  end
  finder.instance = self

  self.size = global_opts.size
  self.bindings = global_opts.bindings

  self.old_win = vim.api.nvim_get_current_win()
  self.old_buf = vim.api.nvim_get_current_buf()

  self.chain_fn = opts.chain
  self.open_fn = opts.open or function() end
  self.preview_fn = opts.preview

  if self.preview_fn then
    self.preview = preview.new(self.preview_fn)
  end
  self.results = results.new()
  self.input = input.new()

  self.full_screen = false

  events.on(self, constants.event.results_opened, finder.open)
  events.on(self, constants.event.input_changed, finder.search)
  events.on(self, constants.event.error, finder.close_with_err)
  events.native(self, constants.event.resize, finder.update)
  events.native(self, constants.event.buf_leave, finder.close, { buffer = self.input.buf })

  for lhs, action in pairs(self.bindings) do
    vim.keymap.set("i", lhs, self:bind_action(action), { buffer = self.input.buf })
  end

  self:update()

  return self
end

return finder
