local close = require("yaff.stream.common").close
local identity = require("yaff.stream.common").identity
local generator = {}
local uv = vim.loop
generator.__index = generator

function generator:stop()
  close(self.output_stream)
  if self.handle then
    self.handle:kill("SIGTERM")
  end
end

function generator:start_fun()
  self.output_stream:write(table.concat(self.fun(), "\n"))
  close(self.output_stream)
end

function generator:start_cmd()
  self.handle = uv.spawn(self.command, {
    args = self.args,
    stdio = { nil, self.output_stream, nil },
  }, function()
    close(self.output_stream)
    close(self.handle)
  end)
end

function generator:start()
  if self.command then
    self:start_cmd()
  elseif self.fun then
    self:start_fun()
  end
end

function generator.new(opts)
  local s = setmetatable({ keys = {} }, generator)

  s.output_stream = uv.new_pipe(false)

  s.command = opts.command
  s.fun = opts.fun
  s.args = opts.args or {}

  s.parser = function(x)
    local parser = opts.parser or identity
    return parser({ text = x })
  end

  return s
end

return generator
