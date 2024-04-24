local uv = vim.loop
local events = {}
events.event = {
  resize = "VimResized",
  buf_leave = "BufLeave",
  cursor_moved = "CursorMoved",
  win_leave = "WinLeave",
  results_retrieved = "ResultsRetrieved",
  empty_results_retrieved = "EmptyResultsRetrieved",
  result_focused = "ResultFocused",
  results_opened = "ResultsOpened",
  input_changed = "InputChanged",
  new_request = "NewRequest",
  new_opts = "NewOpts",
  error = "Error",
}

local function alive_handler(self, module, evt)
  return self.handlers[module] and self.handlers[module][evt]
end

local function make_callback(self, module, evt, callback)
  return function(payload)
    vim.schedule(function()
      if alive_handler(self, module, evt) then
        callback(module, payload.data)
      end
    end)
  end
end

local function set_handler(self, module, main_evt, evt, opts)
  if not self.handlers[module] then
    self.handlers[module] = {}
  end

  self.handlers[module][evt] = vim.api.nvim_create_autocmd(main_evt, opts)
end

function events:on(module, evt, callback)
  local opts = {
    group = self.group,
    callback = make_callback(self, module, evt, callback),
    pattern = evt,
  }

  set_handler(self, module, "User", evt, opts)
end

function events:native(module, evt, callback, opts)
  opts = vim.tbl_deep_extend("force", {
    group = self.group,
    callback = make_callback(self, module, evt, callback),
  }, opts or {})

  set_handler(self, module, evt, evt, opts)
end

function events:clear(module, evt)
  if not alive_handler(self, module, evt) then
    return
  end

  vim.api.nvim_del_autocmd(self.handlers[module][evt])
  self.handlers[module][evt] = nil
end

function events:clear_module(module)
  for evt, _ in pairs(self.handlers[module] or {}) do
    self:clear(module, evt)
  end
  self.handlers[module] = nil
end

function events:fire(evt, data, delay)
  self:cancel(evt)
  self.timers[evt] = vim.defer_fn(function()
    vim.api.nvim_exec_autocmds("User", { group = self.group, pattern = evt, data = data })
  end, delay or 0)
end

function events:fire_native(evt, delay)
  self:cancel(evt)
  self.timers[evt] = vim.defer_fn(function()
    vim.api.nvim_exec_autocmds(evt, { group = self.group })
  end, delay or 0)
end

function events:cancel(evt)
  local timer = self.timers[evt]
  if timer and uv.is_active(timer) then
    uv.timer_stop(timer)
    uv.close(timer)
    self.timers[evt] = nil
  end
end

function events.new()
  local self = setmetatable(events, { __index = events })

  self.group = vim.api.nvim_create_augroup("Microscope", { clear = false })
  self.timers = {}
  self.handlers = {}

  return self
end

events.global = events.new()

return events
