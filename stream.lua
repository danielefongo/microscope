local stream = {}
local uv = vim.loop
stream.__index = stream

local function close(handle)
  if handle and not handle:is_closing() then
    handle:close()
  end
end

function stream:stop()
  if self.handle then
    close(self.input_stream)
    close(self.output_stream)
    self.handle:kill("SIGTERM")
  end
end

function stream:start()
  local output = ""

  self.handle = uv.spawn(self.command, {
    args = self.args,
    stdio = { self.input_stream, self.output_stream, nil },
  }, function()
    local lines = vim.split(output, "\n", { trimempty = true })
    if self.cb then
      self.cb(lines)
    end

    close(self.input_stream)
    close(self.output_stream)
    close(self.handle)
  end)

  if self.last then
    uv.read_start(self.output_stream, function(_, data)
      if data then
        output = output .. data
      end
    end)
  end

  if self.input_stream then
    uv.read_start(self.input_stream, function() end)
  end

  if self.input then
    self.input:start(false)
  end
end

function stream.new(input, opts)
  local s = setmetatable({ keys = {} }, stream)

  s.input = input
  s.input_stream = input and input.output_stream
  s.output_stream = uv.new_pipe(false)

  s.command = opts.command
  s.args = opts.args or {}

  return s
end

function stream.chain(list_of_opts, cb)
  local s = nil
  for _, opts in ipairs(list_of_opts) do
    s = stream.new(s, opts)
  end
  s.last = true
  s.cb = cb
  return s
end

return stream
