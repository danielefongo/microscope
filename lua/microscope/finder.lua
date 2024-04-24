local default_layout = require("microscope.builtin.layouts").default
local instance = require("microscope.instance")
local events = require("microscope.events")
local error = require("microscope.api.error")
local scope = require("microscope.api.scope")
local preview = require("microscope.ui.preview")
local results = require("microscope.ui.results")
local input = require("microscope.ui.input")

local finder = {}
finder.__index = finder

local function resume_old_position(self)
  local cursor = vim.api.nvim_win_get_cursor(self.old_win)
  vim.api.nvim_set_current_win(self.old_win)
  vim.api.nvim_set_current_buf(self.old_buf)
  vim.api.nvim_win_set_cursor(self.old_win, { cursor[1], cursor[2] + 1 })
end

function finder:bind_action(fun)
  return function()
    pcall(fun, self)
  end
end

function finder:close()
  self.events:clear_all()
  events.global:clear_all()

  resume_old_position(self)

  self.input:close()
  self.results:close()
  self.preview:close()

  self:stop_search()
  instance.current = nil
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
    self.opts.open(value, self.request, data.metadata)
  end
end

function finder:stop_search()
  self.scope:stop()
end

function finder:search(text)
  self:stop_search()
  self.request = {
    text = text,
    buf = self.old_buf,
    win = self.old_win,
  }
  self.events:fire(events.event.new_request, self.request)
  self.scope:search(self.request, self.opts.args)
end

function finder:update()
  self.events:clear(self, events.event.win_leave)

  if not self.opts.hidden then
    local layout = self.opts.layout({
      finder_size = self.opts.size,
      ui_size = vim.api.nvim_list_uis()[1],
      preview = self.opts.preview ~= nil,
      full_screen = self.opts.full_screen,
    })

    self.preview:show(layout.preview, layout.input == nil)
    self.results:show(layout.results, layout.input == nil)
    self.input:show(layout.input, true)

    self.events:native(self, events.event.win_leave, finder.close)
  else
    self.preview:show()
    self.results:show()
    self.input:show()

    resume_old_position(self)
  end
end

function finder:resume()
  self.old_win = vim.api.nvim_get_current_win()
  self.old_buf = vim.api.nvim_get_current_buf()

  self.request.buf = self.old_buf
  self.request.win = self.old_win

  self:alter(function(opts)
    opts.hidden = false
    return opts
  end)
end

function finder:alter(lambda)
  self:set_opts(lambda(self:get_opts()))
end

function finder:get_opts()
  return vim.deepcopy(self.opts)
end

function finder:set_opts(opts)
  opts.open = opts.open or function(_, _, _) end
  opts.layout = opts.layout or default_layout
  opts.bindings = opts.bindings or {}
  opts.full_screen = opts.full_screen or false
  opts.args = opts.args or {}
  opts.hidden = opts.hidden or false
  opts.preview = opts.preview or function(_, win)
    win:write({ "No preview function provided" })
  end

  for lhs, _ in pairs(self.opts and self.opts.bindings or {}) do
    vim.keymap.del("i", lhs, { buffer = self.input.buf })
    vim.keymap.del("n", lhs, { buffer = self.results.buf })
    vim.keymap.del("n", lhs, { buffer = self.preview.buf })
  end

  self.opts = opts
  self.request = self.request or nil

  self.events:fire(events.event.new_opts, self.opts)

  for lhs, action in pairs(self.opts.bindings) do
    vim.keymap.set("i", lhs, self:bind_action(action), { buffer = self.input.buf })
    vim.keymap.set("n", lhs, self:bind_action(action), { buffer = self.results.buf })
    vim.keymap.set("n", lhs, self:bind_action(action), { buffer = self.preview.buf })
  end

  self.scope = scope.new({
    lens = opts.lens,
    callback = function(list)
      if #list > 0 then
        self.events:fire(events.event.results_retrieved, list)
      else
        self.events:fire(events.event.empty_results_retrieved)
      end
    end,
  })

  vim.defer_fn(function()
    self:update()
  end, 10)
end

function finder.new(opts)
  local self = setmetatable({}, finder)

  if instance.current then
    vim.api.nvim_err_write("microscope: close the hidden finder before opening a new one\n")
    return
  end
  instance.current = self

  self.old_win = vim.api.nvim_get_current_win()
  self.old_buf = vim.api.nvim_get_current_buf()

  self.events = events.new()
  self.preview = preview.new(self.events)
  self.results = results.new(self.events)
  self.input = input.new(self.events)
  self.full_screen = false

  self.events:on(self, events.event.results_opened, finder.open)
  self.events:on(self, events.event.input_changed, finder.search)
  events.global:on(self, events.event.error, finder.close_with_err)
  self.events:native(self, events.event.resize, finder.update)
  self.events:on(self, events.event.win_leave, finder.close)

  self:set_opts(opts)
  self.input:reset()

  return self
end

return finder
