local window = require("microscope.ui.window")
local events = require("microscope.events")
local input = {}

local function on_close(self)
  self:close()
end

function input:show(layout, focus)
  window.show(self, layout, focus)

  if layout == nil then
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

function input:reset()
  vim.api.nvim_buf_set_lines(self.buf, 0, 1, false, {})
  events.fire(events.event.input_changed, "")
end

function input.new()
  local v = window.new(input)

  events.on(v, events.event.microscope_closed, on_close)

  vim.api.nvim_buf_attach(v.buf, false, {
    on_lines = function()
      if vim.api.nvim_buf_line_count(v.buf) > 1 then
        return vim.schedule(function()
          vim.api.nvim_buf_set_lines(v.buf, 0, -1, false, { "> " .. v:text() })
          vim.api.nvim_command("startinsert!")
        end)
      end
      events.fire(events.event.input_changed, v:text())
    end,
  })

  return v
end

return input
