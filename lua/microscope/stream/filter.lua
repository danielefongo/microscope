local close = require("microscope.stream.common").close
local identity = require("microscope.stream.common").identity
local filter = {}
local uv = vim.loop
filter.__index = filter

function filter:stop()
  self.input:stop()
  close(self.output_stream)
  close(self.handle)
end

function filter:start_fun()
  self.input:start()

  uv.read_start(self.input_stream, function(_, data)
    if data then
      self.output_stream:write(self.filter(data))
      close(self.output_stream)
    end
  end)
end

function filter:start_cmd()
  self.handle = uv.spawn(self.command, {
    args = self.args,
    stdio = { self.input_stream, self.output_stream, nil },
  }, function()
    self:stop()
  end)

  self.input:start()

  uv.read_start(self.input_stream, function() end)
end

function filter:start()
  if self.command then
    self:start_cmd()
  elseif self.filter then
    self:start_fun()
  end
end

function filter.new(input, opts)
  local s = setmetatable({ keys = {} }, filter)

  s.input = input
  s.input_stream = input.output_stream
  s.output_stream = uv.new_pipe(false)

  s.command = opts.command
  s.filter = opts.filter
  s.args = opts.args or {}

  s.parser = function(x)
    local parser = opts.parser or identity
    return parser(s.input.parser(x))
  end

  return s
end

return filter
