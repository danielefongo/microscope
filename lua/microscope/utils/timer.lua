local M = {}

local uv = vim.loop

function M.clear_timeout(timer)
  if timer and timer:is_active() then
    uv.timer_stop(timer)
    uv.close(timer)
  end
end

function M.set_interval(start, interval, callback)
  local timer = uv.new_timer()
  local function ontimeout()
    callback(timer)
  end
  uv.timer_start(timer, start, interval, ontimeout)
  return timer
end

return M
