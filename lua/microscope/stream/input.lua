local close = require("microscope.stream.common").close
local identity = require("microscope.stream.common").identity
local input = {}
local uv = vim.loop
input.__index = input

function input:stop()
  close(self.output_stream)
  close(self.handle)
end

function input:start_fun()
  self.fun(function(data)
    self.output_stream:write(table.concat(data, "\n"))
    close(self.output_stream)
  end)
end

function input:start_cmd()
  self.handle = uv.spawn(self.command, {
    args = self.args,
    stdio = { nil, self.output_stream, nil },
  }, function()
    self:stop()
  end)
end

function input:start()
  if self.command then
    self:start_cmd()
  elseif self.fun then
    self:start_fun()
  end
end

function input.new(opts)
  local s = setmetatable({ keys = {} }, input)

  s.output_stream = uv.new_pipe(false)

  s.command = opts.command
  s.fun = opts.fun
  s.args = opts.args or {}

  s.parser = function(x)
    local parser = opts.parser or identity
    return parser({ text = x:gsub("^%s*(.-)%s*$", "%1") })
  end

  return s
end

return input
