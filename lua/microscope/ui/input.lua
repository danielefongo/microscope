local window = require("microscope.ui.window")
local timer = require("microscope.utils.timer")
local events = require("microscope.events")
local input = {}
input.default_prompt = "> "
input.default_spinner = {
  interval = 80,
  delay = 300,
  position = "center",
  symbols = {
    "[    ]",
    "[=   ]",
    "[==  ]",
    "[=== ]",
    "[====]",
    "[ ===]",
    "[  ==]",
    "[   =]",
    "[    ]",
    "[   =]",
    "[  ==]",
    "[ ===]",
    "[====]",
    "[=== ]",
    "[==  ]",
    "[=   ]",
  },
}

local function on_new_request(self)
  if self.spinner_timer then
    return
  end

  self.spinner_timer = timer.set_interval(self.spinner.delay, self.spinner.interval, function()
    local symbol = self.spinner.symbols[self.spinner_step + 1]
    self.spinner_step = self.spinner_step + 1
    if self.spinner_step >= #self.spinner.symbols then
      self.spinner_step = 0
    end

    vim.schedule(function()
      self:set_title(symbol, self.spinner.position)
    end)
  end)
end

local function on_stop_search(self)
  timer.clear_timeout(self.spinner_timer)
  self.spinner_timer = nil

  self.spinner_step = 0

  vim.schedule(function()
    self:set_title("", nil)
  end)
end

local function on_new_opts(self, opts)
  local old_text = self:text()

  self.prompt = opts.prompt
  self.spinner = opts.spinner
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
  on_stop_search(self)
  window.close(self)
  self.old_text = nil
end

function input.new(events_instance)
  local v = window.new(input, events_instance)

  v.spinner_step = 0
  v.spinner = input.default_spinner
  v.prompt = input.default_prompt
  v.events:on(v, events.event.new_opts, on_new_opts)
  v.events:on(v, events.event.new_request, on_new_request)
  v.events:on(v, events.event.empty_results_retrieved, on_stop_search)
  v.events:on(v, events.event.results_retrieved, on_stop_search)

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
