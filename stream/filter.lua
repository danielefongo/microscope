local close = require("yaff.stream.common").close
local filter = {}
local uv = vim.loop
filter.__index = filter

function filter:stop()
  if self.handle then
    close(self.input_stream)
    close(self.output_stream)
    self.handle:kill("SIGTERM")
  end
end

function filter:start()
  self.handle = uv.spawn(self.command, {
    args = self.args,
    stdio = { self.input_stream, self.output_stream, nil },
  }, function()
    close(self.input_stream)
    close(self.output_stream)
    close(self.handle)
  end)

  uv.read_start(self.input_stream, function() end)

  if self.input then
    self.input:start(false)
  end
end

function filter.new(input, opts)
  local s = setmetatable({ keys = {} }, filter)

  s.input = input
  s.input_stream = input.output_stream
  s.output_stream = uv.new_pipe(false)

  s.command = opts.command
  s.args = opts.args or {}

  return s
end

return filter
