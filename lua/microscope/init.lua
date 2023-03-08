local constants = require("microscope.constants")
local preview = require("microscope.preview")
local results = require("microscope.results")
local events = require("microscope.events")
local input = require("microscope.input")
local stream = require("microscope.stream")
local shape = require("microscope.shape")
local microscope = {}
microscope.__index = microscope

function microscope:bind_action(fun)
  return function()
    pcall(fun, self)
  end
end

function microscope:close()
  events.clear_module(self)
  events.fire(constants.event.microscope_closed)
  self:stop_search()
end

function microscope:open(data)
  self:close()
  vim.api.nvim_set_current_win(self.old_win)
  vim.api.nvim_set_current_buf(self.old_buf)
  for _, value in ipairs(data) do
    self.open_fn(value, self.old_win, self.old_buf)
  end
end

function microscope:stop_search()
  if self.find then
    self.find:stop()
  end
end

function microscope:search(text)
  self:stop_search()
  self.find = stream.chain(self.chain_fn(text, self.old_win, self.old_buf), function(list, parser)
    if #list > 0 then
      events.fire(constants.event.results_retrieved, { list = list, parser = parser })
    else
      events.fire(constants.event.empty_results_retrieved)
    end
  end)
  self.find:start()
end

function microscope:update()
  local layout = shape.generate(self.size, self.preview_fn ~= nil)

  if layout then
    return events.fire(constants.event.layout_updated, layout)
  else
    self:close()
    vim.api.nvim_err_writeln("microscope: window too small to display")
  end
end

function microscope:finder(opts)
  return function()
    self.old_win = vim.api.nvim_get_current_win()
    self.old_buf = vim.api.nvim_get_current_buf()

    self.chain_fn = opts.chain
    self.open_fn = opts.open
    self.preview_fn = opts.preview

    if self.preview_fn then
      self.preview = preview.new(self.preview_fn)
    end
    self.results = results.new()
    self.input = input.new()

    events.on(self, constants.event.results_opened, microscope.open)
    events.on(self, constants.event.input_changed, microscope.search)
    events.native(self, constants.event.resize, microscope.update)
    events.native(self, constants.event.buf_leave, microscope.close, { buffer = self.input.buf })

    for lhs, action in pairs(self.bindings) do
      vim.keymap.set("i", lhs, self:bind_action(action), { buffer = self.input.buf })
    end

    self:update()
  end
end

function microscope.setup(opts)
  local v = setmetatable({ keys = {} }, microscope)

  v.size = opts.size
  v.bindings = opts.bindings

  return v
end

return microscope
