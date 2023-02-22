local close = require("yaff.stream.common").close
local generator = {}
local uv = vim.loop
generator.__index = generator

function generator:stop()
  if self.handle then
    close(self.output_stream)
    self.handle:kill("SIGTERM")
  end
end

function generator:start()
  self.handle = uv.spawn(self.command, {
    args = self.args,
    stdio = { self.input_stream, self.output_stream, nil },
  }, function()
    close(self.output_stream)
    close(self.handle)
  end)
end

function generator.new(opts)
  local s = setmetatable({ keys = {} }, generator)

  s.output_stream = uv.new_pipe(false)

  s.command = opts.command
  s.args = opts.args or {}

  return s
end

return generator
