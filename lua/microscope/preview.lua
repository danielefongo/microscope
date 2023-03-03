local events = require("microscope.events")
local constants = require("microscope.constants")
local preview = {}
preview.__index = preview

function preview:close()
  events.clear_module(self)
  vim.api.nvim_win_set_buf(self.win, self.buf)
  vim.api.nvim_buf_delete(self.buf, { force = true })
end

function preview:show(data)
  self.preview_fun(data, self.win, self.buf)
end

function preview:clear()
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, {})
end

function preview:scroll(dir, amount)
  local counts = vim.api.nvim_buf_line_count(self.buf)
  local cursor = vim.api.nvim_win_get_cursor(self.win)[1]
  if dir == constants.DOWN then
    vim.api.nvim_win_set_cursor(self.win, { math.min(cursor + amount, counts), 0 })
  elseif dir == constants.UP then
    vim.api.nvim_win_set_cursor(self.win, { math.max(cursor - amount, 1), 0 })
  end
end

function preview:update(opts)
  local layout = opts.preview

  if not self.win then
    self.win = vim.api.nvim_open_win(self.buf, false, layout)
  else
    vim.api.nvim_win_set_config(self.win, layout)
  end

  vim.api.nvim_buf_set_option(self.buf, "buftype", "prompt")
  vim.api.nvim_win_set_option(self.win, "cursorline", true)
end

function preview.new(preview_fun)
  local v = setmetatable({ keys = {} }, preview)

  v.preview_fun = preview_fun
  v.buf = vim.api.nvim_create_buf(false, true)

  events.on(v, constants.event.result_focused, preview.show)
  events.on(v, constants.event.empty_results_retrieved, preview.clear)
  events.on(v, constants.event.layout_updated, preview.update)
  events.on(v, constants.event.microscope_closed, preview.close)

  return v
end

return preview
