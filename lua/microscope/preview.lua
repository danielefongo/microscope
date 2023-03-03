local events = require("microscope.events")
local constants = require("microscope.constants")
local preview = {}
preview.__index = preview

function preview:close()
  events.clear_module(constants.module.preview)
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
  if not self.win then
    self.win = vim.api.nvim_open_win(self.buf, false, opts)
  else
    vim.api.nvim_win_set_config(self.win, opts)
  end

  vim.api.nvim_buf_set_option(self.buf, "buftype", "prompt")
  vim.api.nvim_win_set_option(self.win, "cursorline", true)
end

function preview.new(preview_fun)
  local v = setmetatable({ keys = {} }, preview)

  v.preview_fun = preview_fun
  v.buf = vim.api.nvim_create_buf(false, true)

  events.on(constants.module.preview, constants.event.result_focused, function(data)
    v.preview_fun(data, v.win, v.buf)
  end)

  events.on(constants.module.preview, constants.event.empty_results_retrieved, function()
    v:clear()
  end)

  events.on(constants.module.preview, constants.event.layout_updated, function(layout)
    v:update(layout.preview)
  end)

  events.on(constants.module.preview, constants.event.microscope_closed, function()
    v:close()
  end)

  return v
end

return preview
