local error = require("microscope.api.error")
local scheduled = require("microscope.api.scheduled")
local command = require("microscope.api.command")
local lens = {}
lens.__index = lens

local function is_alive(co)
  return co ~= nil and coroutine.status(co) ~= "dead"
end

function lens:input_read(to_array)
  for i = 1, #self.inputs, 1 do
    if is_alive(self.inputs[i].coroutine) then
      local data = self.inputs[i]:read()

      while data == "" do
        self:write("")
        data = self.inputs[i]:read()
      end

      if data ~= nil and to_array then
        return vim.split(data, "\n", { trimempty = true })
      elseif data ~= nil then
        return data
      end
    end
  end
end

function lens:input_read_iter(to_array)
  return function()
    return self:input_read(to_array)
  end
end

function lens:read()
  if not is_alive(self.coroutine) then
    self.coroutine = nil
    return
  end

  local ok, value = coroutine.resume(self.coroutine, self.flow, self.request, self.context)
  if not ok then
    error.critical(debug.traceback(self.coroutine, value))
  end
  return value
end

function lens:write(data)
  if type(data) == "string" then
    coroutine.yield(data)
  elseif type(data) == "table" then
    coroutine.yield(table.concat(data, "\n") .. "\n")
  end
end

function lens:stop()
  self.context = {}
  for _, input in pairs(self.inputs) do
    input:stop()
  end
  self.stopped = true
end

function lens:feed(request)
  self.stopped = false
  self.request = request
  self.coroutine = coroutine.create(self.fn)

  for _, input in pairs(self.inputs) do
    input:feed(request)
  end
end

function lens:create_flow()
  self.flow = {
    can_read = function()
      return #self.inputs > 0
    end,
    read = function()
      return self:input_read(false)
    end,
    read_array = function()
      return self:input_read(true)
    end,
    read_iter = function()
      return self:input_read_iter(false)
    end,
    read_array_iter = function()
      return self:input_read_iter(true)
    end,
    stop = function()
      self:stop()
    end,
    stopped = function()
      return self.stopped
    end,
    write = function(data)
      self:write(data)
    end,
    text = function()
      return self.request.text
    end,
    fn = function(fn, ...)
      return scheduled.fn(self.flow, fn, ...)
    end,
    await = function(fn, cb, ...)
      return scheduled.await(self.flow, fn, cb, ...)
    end,
    command = function(opts)
      return command.command(self.flow, opts)
    end,
    spawn = function(opts)
      return command.spawn(self.flow, opts)
    end,
  }
end

function lens.new(opts)
  local l = setmetatable({}, lens)

  l.inputs = {}
  local inputs_specs = opts.inputs
  for _, input_spec in pairs(inputs_specs or {}) do
    table.insert(l.inputs, lens.new(input_spec))
  end
  l.fn = opts.fun
  l.context = {}
  l.stopped = false
  l:create_flow()

  return l
end

return lens
