local constants = require("microscope.constants")
local results = require("microscope.results")
local events = require("microscope.events")
local preview = require("microscope.preview")
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
  events.clear_module(constants.module.microscope)
  events.fire(constants.event.microscope_closed)
end

function microscope:update()
  local layout = shape.generate(self.size, self.has_preview)

  if layout then
    return events.fire(constants.event.layout_updated, layout)
  end

  self:close()
  vim.schedule(function()
    vim.api.nvim_err_writeln("microscope: window too small to display")
  end)
end

function microscope:finder(opts)
  return function()
    local chain_fn = opts.chain
    local open_fn = opts.open
    local preview_fn = opts.preview

    self.has_preview = preview_fn ~= nil

    if self.has_preview then
      self.preview = preview.new(preview_fn)
    end
    self.results = results.new()
    self.input = input.new()

    local old_win = vim.api.nvim_get_current_win()
    local old_buf = vim.api.nvim_get_current_buf()

    events.on(constants.module.microscope, constants.event.result_opened, function(data)
      vim.schedule(function()
        self:close()
        vim.api.nvim_set_current_win(old_win)
        vim.api.nvim_set_current_buf(old_buf)
        open_fn(data, old_win, old_buf)
      end)
    end)

    events.on(constants.module.microscope, constants.event.input_changed, function(text)
      if self.find then
        self.find:stop()
      end
      self.find = stream.chain(chain_fn(text), function(list, parser)
        vim.schedule(function()
          if #list > 0 then
            events.fire(constants.event.results_retrieved, { list = list, parser = parser })
          else
            events.fire(constants.event.empty_results_retrieved)
          end
        end)
      end)
      self.find:start()
    end)

    events.native(constants.module.microscope, constants.event.resize, function()
      self:update()
    end)

    events.native(constants.module.microscope, constants.event.buf_leave, function()
      self:close()
    end, { buffer = self.input.buf })

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
  v.find = nil

  return v
end

return microscope
