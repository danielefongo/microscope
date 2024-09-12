local window = require("microscope.ui.window")
local events = require("microscope.events")
local input = {}
input.default_prompt = "> "

local function on_new_opts(self, opts)
  local old_text = self:text()

  local updated = self.args and not vim.deep_equal(self.args, opts.args)
  if updated then
    self.events:fire(events.event.input_changed, self:text())
  end
  self.args = opts.args
  self.prompt = opts.prompt
  self:set_text(old_text)
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

function input:set_text(text)
  vim.fn.prompt_setprompt(self.buf, self.prompt)
  self:write({ self.prompt .. text })
end

function input:text()
  return self:read(0, 1)[1]:sub(#self.prompt):gsub("^%s*(%s*.-)%s*$", "%1")
end

function input:reset()
  self:clear()
end

function input:close()
  window.close(self)
  self.old_text = nil
end

function input.new(events_instance)
  local v = window.new(input, events_instance)

  v.prompt = input.default_prompt
  v.events:on(v, events.event.new_opts, on_new_opts)

  vim.api.nvim_buf_attach(v.buf, false, {
    on_lines = function()
      if vim.api.nvim_buf_line_count(v.buf) > 1 then
        return vim.schedule(function()
          v:write({ v.prompt .. v:text() })
          vim.api.nvim_command("startinsert!")
        end)
      end
      if v:text() == v.old_text then
        return
      end
      v.events:fire(events.event.input_changed, v:text())
      v.old_text = v:text()
    end,
  })

  return v
end

return input
