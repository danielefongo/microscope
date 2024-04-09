local command = {}
local uv = vim.loop
command.__index = command

local function split_last_newline(text)
  local idx = text:reverse():find("\n")
  if idx == nil or idx == 1 then
    return text, ""
  end
  return text:sub(1, -idx), text:sub(1 - idx)
end

function command:close()
  if self.input then
    self.input:close()
  end

  self.output_stream:read_stop()
  self.output_stream:shutdown()

  if not self.handle or not self.handle:is_active() then
    return
  end

  if self.command then
    self.handle:close()
    self.handle:kill(vim.loop.constants.SIGTERM)
  else
    self.handle:stop()
  end
end

function command:spawn()
  if self.command then
    self.handle = uv.spawn(self.command, {
      args = self.args,
      cwd = self.cwd,
      stdio = { self.input_stream, self.output_stream, nil },
    }, function()
      self:close()
    end)
  else
    self.handle = uv.new_idle()
    self.handle:start(function()
      local co = coroutine.create(self.iterator)
      local success, out = coroutine.resume(co)
      if success and out then
        if type(out) == "table" then
          out = table.concat(out, "\n") .. "\n"
        end

        self.output = self.output .. out
        self.output_stream:write(out)
      else
        self:close()
      end
    end)
  end

  if self.input then
    self.input:spawn()
  end
end

function command:read_start(last)
  if self.input then
    self.input:read_start(false)
  end

  if not last then
    return function() end
  end

  if self.command then
    uv.read_start(self.output_stream, function(_, data)
      if data then
        self.output = self.output .. data
      end
    end)
  end

  return function()
    if self.handle and self.handle:is_active() and not self.output:find("\n") then
      return ""
    end

    local result
    if self.handle and self.handle:is_active() or self.output ~= "" then
      result, self.output = split_last_newline(self.output)
      return result
    end
  end
end

function command:get_iter()
  self:spawn()
  return self:read_start(true)
end

function command:into(flow)
  for shell_out in self:get_iter() do
    if flow.stopped() then
      self:close()
    end
    flow.write(shell_out)
  end
end

function command:collect()
  local outputs = ""
  for shell_out in self:get_iter() do
    outputs = outputs .. shell_out
    coroutine.yield("")
  end
  return outputs
end

local function command_new(opts, instance)
  local self = setmetatable({ keys = {} }, command)

  if instance then
    self.input = instance
    self.input_stream = self.input.output_stream
  end
  self.output_stream = uv.new_pipe(false)
  self.output = ""

  self.command = opts.cmd
  self.args = opts.args or {}
  self.iterator = opts.iterator
  if opts.iterator then
    self.co = coroutine.create(self.iterator)
  end

  return self
end

function command:pipe(cmd, ...)
  local args = { ... }
  return command_new({ cmd = cmd, args = args }, self)
end

function command.iter(iterator)
  return command_new({ iterator = iterator })
end

function command.fn(fun, ...)
  return command.await(function(cb, ...)
    cb(fun(...))
  end, ...)
end

function command.await(fun, ...)
  local params = { ... }

  local output
  local finished

  local cb = function(out)
    output = out
    finished = true
  end

  local co = coroutine.create(function()
    vim.schedule(function()
      fun(cb, unpack(params))
    end)
  end)

  coroutine.resume(co)

  local iterator = function()
    if not finished then
      return ""
    end

    local new_out = output
    output = nil
    return new_out
  end

  return command_new({ iterator = iterator })
end

function command.shell(cmd, ...)
  return command.pipe(nil, cmd, ...)
end

return command
