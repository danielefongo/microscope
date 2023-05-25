local window = require("microscope.ui.window")
local events = require("microscope.events")
local input = {}

local function on_close(self)
  self:close()
end

function input:show(build)
  window.show(self, build)

  if build == nil then
    self:set_buf_opt("buftype", "nowrite")
    vim.api.nvim_command("stopinsert!")
  else
    self:set_buf_opt("buftype", "prompt")
    vim.api.nvim_command("startinsert!")
    vim.fn.prompt_setprompt(self.buf, "> ")
  end
end

function input:text()
  return vim.api.nvim_buf_get_lines(self.buf, 0, 1, false)[1]:sub(3):gsub("^%s*(%s*.-)%s*$", "%1")
end

function input.new()
  local v = window.new(input)

  events.on(v, events.event.microscope_closed, on_close)

  vim.api.nvim_buf_attach(v.buf, false, {
    on_lines = function()
      events.fire(events.event.input_changed, v:text())
    end,
  })

  return v
end

return input
