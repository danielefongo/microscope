local events = require("microscope.events")
local constants = require("microscope.constants")
local results = {}
results.__index = results

function results:focused()
  local cursor = vim.api.nvim_win_get_cursor(self.win)[1]
  local line = vim.api.nvim_buf_get_lines(self.buf, cursor - 1, cursor, false)[1]
  if line and line ~= "" then
    return self.parser(line)
  end
end

function results:focus_line(line)
  vim.api.nvim_win_set_cursor(self.win, { line, 0 })
  local focused = self:focused()
  if focused then
    events.fire(constants.event.result_focused, focused)
  end
end

function results:focus(dir)
  local counts = vim.api.nvim_buf_line_count(self.buf)
  local cursor = vim.api.nvim_win_get_cursor(self.win)[1]
  if dir == constants.DOWN then
    cursor = (cursor - 1 + 1) % counts + 1
  elseif dir == constants.UP then
    cursor = (cursor - 1 - 1) % counts + 1
  end
  self:focus_line(cursor)
end

function results:close()
  events.clear_module(constants.module.results)
  vim.api.nvim_buf_delete(self.buf, { force = true })
end

function results:open()
  events.fire(constants.event.result_opened, self:focused())
end

function results:on_new()
  vim.schedule(function()
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, {})
  end)
end

function results:on_data(list, parser)
  self.parser = parser

  vim.schedule(function()
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, list)
    self:focus_line(1)
  end)
end

function results:update(opts)
  if not self.win then
    self.win = vim.api.nvim_open_win(self.buf, false, opts)
  else
    vim.api.nvim_win_set_config(self.win, opts)
  end

  vim.api.nvim_buf_set_option(self.buf, "buftype", "prompt")
  vim.api.nvim_win_set_option(self.win, "cursorline", true)
end

function results.new()
  local v = setmetatable({ keys = {} }, results)

  v.buf = vim.api.nvim_create_buf(false, true)

  events.on(constants.module.results, constants.event.layout_updated, function(layout)
    v:update(layout.results)
  end)

  events.on(constants.module.results, constants.event.input_changed, function()
    v:on_new()
  end)

  events.on(constants.module.results, constants.event.results_retrieved, function(data)
    v:on_data(data.list, data.parser)
  end)

  events.on(constants.module.results, constants.event.microscope_closed, function()
    v:close()
  end)

  return v
end

return results
