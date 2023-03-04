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

function results:select()
  local cursor = vim.api.nvim_win_get_cursor(self.win)[1]
  local line = vim.api.nvim_buf_get_lines(self.buf, cursor - 1, cursor, false)[1]

  if line then
    if not self.selected_lines[cursor] then
      vim.api.nvim_buf_set_lines(self.buf, cursor - 1, cursor, true, { "> " .. line })
      self.selected_lines[cursor] = line
    else
      vim.api.nvim_buf_set_lines(self.buf, cursor - 1, cursor, true, { self.selected_lines[cursor] })
      self.selected_lines[cursor] = nil
    end
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
  events.clear_module(self)
  vim.api.nvim_buf_delete(self.buf, { force = true })
end

function results:open()
  local to_be_open = {}

  if #self.selected_lines == 0 then
    table.insert(to_be_open, self:focused())
  end

  for _, value in pairs(self.selected_lines) do
    table.insert(to_be_open, self.parser(value))
  end

  events.fire(constants.event.results_opened, to_be_open)

  self.selected_lines = {}
end

function results:reset()
  self.selected_lines = {}
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, {})
end

function results:show(data)
  self.parser = data.parser

  vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, data.list)
  self:focus_line(1)
end

function results:update(opts)
  local layout = opts.results

  if not self.win then
    self.win = vim.api.nvim_open_win(self.buf, false, layout)
  else
    vim.api.nvim_win_set_config(self.win, layout)
  end

  self:focus_line(1)
  vim.api.nvim_buf_set_option(self.buf, "buftype", "prompt")
  vim.api.nvim_win_set_option(self.win, "cursorline", true)
end

function results.new()
  local v = setmetatable({ keys = {} }, results)

  v.buf = vim.api.nvim_create_buf(false, true)
  v.selected_lines = {}

  events.on(v, constants.event.layout_updated, results.update)
  events.on(v, constants.event.input_changed, results.reset)
  events.on(v, constants.event.results_retrieved, results.show)
  events.on(v, constants.event.microscope_closed, results.close)

  return v
end

return results
