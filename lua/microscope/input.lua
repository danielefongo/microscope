local events = require("microscope.events")
local constants = require("microscope.constants")
local input = {}
input.__index = input

function input:text()
  return string.sub(vim.api.nvim_buf_get_lines(self.buf, 0, 1, false)[1], 3)
end

function input:close()
  events.clear_module(self)
  vim.api.nvim_buf_delete(self.buf, { force = true })
end

function input:update(opts)
  local layout = opts.input

  if not self.win then
    self.win = vim.api.nvim_open_win(self.buf, true, layout)
  else
    vim.api.nvim_win_set_config(self.win, layout)
  end

  vim.api.nvim_buf_set_option(self.buf, "buftype", "prompt")
  vim.fn.prompt_setprompt(self.buf, "> ")
  vim.api.nvim_command("startinsert")
end

function input.new()
  local v = setmetatable({ keys = {} }, input)

  v.buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_attach(v.buf, false, {
    on_lines = function()
      events.fire(constants.event.input_changed, v:text())
    end,
  })

  events.on(v, constants.event.layout_updated, input.update)
  events.on(v, constants.event.microscope_closed, input.close)

  return v
end

return input
