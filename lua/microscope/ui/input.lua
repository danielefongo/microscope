local window = require("microscope.ui.window")
local events = require("microscope.events")
local input = {}

local function on_close(self)
  self:close()
  self.old_text = nil
end

local function on_new_opts(self, opts)
  local old_text = self:text()

  self.prompt = opts.prompt
  vim.fn.prompt_setprompt(self.buf, self.prompt)
  self:write({ self.prompt .. old_text })
end

function input:show(layout, focus)
  window.show(self, layout, focus)

  if layout == nil then
    self:set_buf_opt("buftype", "nowrite")
    vim.api.nvim_command("stopinsert!")
  else
    self:set_buf_opt("buftype", "prompt")
    vim.api.nvim_command("startinsert!")
  end
end

function input:text()
  if not self.prompt then
    return ""
  end

  return self:read(0, 1)[1]:sub(#self.prompt):gsub("^%s*(%s*.-)%s*$", "%1")
end

function input:reset()
  self:clear()
end

function input.new()
  local v = window.new(input)

  events.on(v, events.event.microscope_closed, on_close)
  events.on(v, events.event.new_opts, on_new_opts)

  vim.api.nvim_buf_attach(v.buf, false, {
    on_lines = function()
      if v:text() == v.old_text then
        return
      end
      if vim.api.nvim_buf_line_count(v.buf) > 1 then
        return vim.schedule(function()
          v:write({ v.prompt .. v:text() })
          vim.api.nvim_command("startinsert!")
        end)
      end
      events.fire(events.event.input_changed, v:text())
      v.old_text = v:text()
    end,
  })

  return v
end

return input
