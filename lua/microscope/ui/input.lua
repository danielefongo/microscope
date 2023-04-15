local window = require("microscope.ui.window")
local events = require("microscope.events")
local constants = require("microscope.constants")
local input = {}
setmetatable(input, window)

local function on_layout_updated(self, layout)
  self:show(layout.input, true)

  vim.api.nvim_buf_set_option(self.buf, "buftype", "prompt")
  vim.fn.prompt_setprompt(self.buf, "> ")
  vim.api.nvim_command("startinsert")
end

local function on_close(self)
  events.clear_module(self)
  self:close()
end

function input:text()
  return vim.api.nvim_buf_get_lines(self.buf, 0, 1, false)[1]:sub(3):gsub("^%s*(%s*.-)%s*$", "%1")
end

function input.new(preview_fun)
  local v = setmetatable(input, { __index = window })

  v.preview_fun = preview_fun
  v:new_buf()

  events.on(v, constants.event.layout_updated, on_layout_updated)
  events.on(v, constants.event.microscope_closed, on_close)

  vim.api.nvim_buf_attach(v.buf, false, {
    on_lines = function()
      events.fire(constants.event.input_changed, v:text())
    end,
  })

  return v
end

return input
