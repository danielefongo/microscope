local uv = vim.loop
local events = {}
events.handlers = {}
events.timers = {}
events.group = vim.api.nvim_create_augroup("Microscope", { clear = false })
events.event = {
  resize = "VimResized",
  buf_leave = "BufLeave",
  cursor_moved = "CursorMoved",
  win_leave = "WinLeave",
  microscope_closed = "MicroscopeClosed",
  results_retrieved = "ResultsRetrieved",
  empty_results_retrieved = "EmptyResultsRetrieved",
  result_focused = "ResultFocused",
  results_opened = "ResultsOpened",
  input_changed = "InputChanged",
  error = "Error",
}

local function unschedule(evt)
  local timer = events.timers[evt]
  if timer and uv.is_active(timer) then
    uv.timer_stop(timer)
    uv.close(timer)
    events.timers[evt] = nil
  end
end

local function alive_handler(module, evt)
  return events.handlers[module] and events.handlers[module][evt]
end

local function make_callback(module, evt, callback)
  return function(payload)
    vim.schedule(function()
      if alive_handler(module, evt) then
        callback(module, payload.data)
      end
    end)
  end
end

local function set_handler(module, main_evt, evt, opts)
  if not events.handlers[module] then
    events.handlers[module] = {}
  end

  events.handlers[module][evt] = vim.api.nvim_create_autocmd(main_evt, opts)
end

function events.on(module, evt, callback)
  local opts = {
    group = events.group,
    callback = make_callback(module, evt, callback),
    pattern = evt,
  }

  set_handler(module, "User", evt, opts)
end

function events.native(module, evt, callback, opts)
  opts = vim.tbl_deep_extend("force", {
    group = events.group,
    callback = make_callback(module, evt, callback),
  }, opts or {})

  set_handler(module, evt, evt, opts)
end

function events.clear(module, evt)
  if not alive_handler(module, evt) then
    return
  end

  vim.api.nvim_del_autocmd(events.handlers[module][evt])
  events.handlers[module][evt] = nil
end

function events.clear_module(module)
  for evt, _ in pairs(events.handlers[module] or {}) do
    events.clear(module, evt)
  end
  events.handlers[module] = nil
end

function events.fire(evt, data, delay)
  unschedule(evt)
  events.timers[evt] = vim.defer_fn(function()
    vim.api.nvim_exec_autocmds("User", { group = events.group, pattern = evt, data = data })
  end, delay or 0)
end

return events
