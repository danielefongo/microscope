local stream = {}
local uv = vim.loop
stream.__index = stream

local function on_chunk(callback)
  return function(_, chunk)
    if chunk then
      local vals = vim.split(chunk, "\n", { trimempty = true })
      for _, d in pairs(vals) do
        callback(d)
      end
    end
  end
end

local function shutdown(handle)
  if handle then
    handle:shutdown()
  end
end

local function close(handle)
  if handle then
    handle:read_stop()
    handle:close()
  end
end

local function read(handle, fn)
  if handle then
    handle:read_start(fn)
  end
end

local function write(handle, line)
  if handle then
    handle:write(line)
  end
end

local function generate(input, opts)
  local s = setmetatable({ keys = {} }, stream)

  local input_stream = input and input.output_stream
  local transform_stream = uv.new_pipe(false)
  local output_stream = uv.new_pipe(false)

  local command = opts.command
  local args = opts.args or {}
  local cb = opts.cb or function(_) end
  local on_end = opts.on_end or function(_) end

  local handle
  handle = uv.spawn(command, {
    args = args,
    stdio = { input_stream, transform_stream },
  }, function()
    shutdown(output_stream)
    close(transform_stream)
    close(input_stream)
    handle:close()
    on_end(s)
  end)

  local function callback(d)
    write(output_stream, d .. "\n")
    cb(d)
  end

  s.handle = handle
  s.output_stream = output_stream
  s.transform_stream = transform_stream
  s.callback = callback
  s.input = input

  return s
end

function stream:start()
  if self.input then
    self.input:start()
  end
  read(self.transform_stream, on_chunk(self.callback))
end

function stream:stop()
  if self.handle then
    self.handle:kill("SIGTERM")
  end
  if self.input then
    self.input:stop()
  end
end

function stream:next(opts)
  generate(self, opts)
end

function stream.new(opts)
  return generate(nil, opts)
end

function stream.chain(list_of_opts)
  local s = nil
  for _, opts in ipairs(list_of_opts) do
    s = generate(s, opts)
  end
  return s
end

return stream
