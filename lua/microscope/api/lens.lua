local error = require("microscope.api.error")
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
  if self.stopped then
    self:input_read(false)
  end

  if not is_alive(self.coroutine) then
    self.coroutine = nil
    return
  end

  local ok, value = coroutine.resume(self.coroutine, self.flow, self.request, self.args, self.context)
  if not ok then
    error.critical(debug.traceback(self.coroutine, value))
  end
  return value
end

function lens:write(data)
  if self.stopped then
    return ""
  end
  if type(data) == "string" then
    coroutine.yield(data)
  elseif type(data) == "table" then
    coroutine.yield(table.concat(data, "\n") .. "\n")
  end
end

function lens:stop()
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
    cmd = command,
  }
end

function lens.new(opts)
  local l = setmetatable({}, lens)

  l.inputs = {}
  l.defaults = {}
  local inputs_specs = opts.inputs
  for _, input_spec in pairs(inputs_specs or {}) do
    local input_lens = lens.new(input_spec)
    table.insert(l.inputs, input_lens)
    l.defaults = vim.tbl_deep_extend("force", l.defaults, input_lens.defaults)
  end
  l.defaults = vim.tbl_deep_extend("force", l.defaults, opts.args or {})
  l.args = l.defaults
  l.fn = opts.fun
  l.context = {}
  l.stopped = false
  l:create_flow()

  return l
end

function lens:set_args(args)
  args = args or {}
  local function check_deep(new_args, allowed_args)
    for key, value in pairs(new_args) do
      if allowed_args[key] == nil then
        return true
      end
      if type(value) ~= type(allowed_args[key]) then
        return false
      end
      if type(value) == "table" then
        return check_deep(value, allowed_args[key])
      end
    end
    return true
  end

  local is_valid = check_deep(args, self.defaults)

  if not is_valid then
    return nil, self.defaults
  end

  self.args = vim.tbl_deep_extend("force", self.defaults, args or {})

  for _, input_lens in pairs(self.inputs) do
    input_lens:set_args(args)
  end

  return self.args, self.defaults
end

return lens
