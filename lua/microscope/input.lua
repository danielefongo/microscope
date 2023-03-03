local events = require("microscope.events")
local constants = require("microscope.constants")
local input = {}
input.__index = input

function input:text()
  return string.sub(vim.api.nvim_buf_get_lines(self.buf, 0, 1, false)[1], 3)
end

function input:close()
  events.clear_module(constants.module.input)
  vim.api.nvim_buf_delete(self.buf, { force = true })
end

function input:update(opts)
  if not self.win then
    self.win = vim.api.nvim_open_win(self.buf, true, opts)
  else
    vim.api.nvim_win_set_config(self.win, opts)
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

  events.on(constants.module.input, constants.event.layout_updated, function(layout)
    v:update(layout.input)
  end)

  events.on(constants.module.input, constants.event.microscope_closed, function()
    v:close()
  end)

  return v
end

return input
