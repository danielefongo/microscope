local error = require("microscope.api.error")
local command = require("microscope.api.command")
local table_util = require("microscope.utils.table")
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

  local ok, value = coroutine.resume(self.coroutine, self.flow, self.request, self.args, self.context)
  if not ok then
    error.critical(debug.traceback(self.coroutine, value))
  end
  return value
end

function lens:write(data)
  if self.stopped then
    return
  end
  if type(data) == "string" then
    coroutine.yield(data)
  elseif type(data) == "table" then
    coroutine.yield(table.concat(data, "\n") .. "\n")
  end
end

function lens:stop()
  for _, cmd in pairs(self.cmds) do
    cmd:close(true, true)
  end
  self.cmds = setmetatable({}, { __mode = "v" })

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

function lens:consume(cmd)
  for shell_out in cmd:get_iter() do
    if not self.stopped then
      self:write(shell_out)
    end
  end
  cmd:close(true)
end

function lens:collect(cmd, to_array)
  local outputs = ""

  for shell_out in cmd:get_iter() do
    if not self.stopped then
      outputs = outputs .. shell_out
      self:write("")
    end
  end

  if to_array then
    return vim.split(outputs, "\n")
  else
    return outputs
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
    consume = function(cmd)
      self.cmds[#self.cmds + 1] = cmd
      self:consume(cmd)
    end,
    collect = function(cmd, to_array)
      self.cmds[#self.cmds + 1] = cmd
      return self:collect(cmd, to_array)
    end,
  }
end

function lens.new(opts)
  local l = setmetatable({}, lens)

  l.cmds = setmetatable({}, { __mode = "v" })
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

  local is_valid = table_util.same_types(args, self.defaults)

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
