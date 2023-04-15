---@diagnostic disable-next-line: deprecated
local unpack = table.unpack or unpack

local scheduled = {}

local function run(async, flow, fn, ...)
  local params = { ... }
  local output

  local function cb(data)
    output = data
  end

  vim.schedule(function()
    if async then
      fn(cb, unpack(params))
    else
      output = fn(unpack(params))
    end
  end)

  while not output do
    coroutine.yield("")
    if flow.stopped() then
      coroutine.yield()
    end
  end

  return output
end

function scheduled.fn(flow, fn, ...)
  return run(false, flow, fn, ...)
end

function scheduled.await(flow, fn, ...)
  return run(true, flow, fn, ...)
end

return scheduled
