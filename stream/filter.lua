local close = require("yaff.stream.common").close
local identity = require("yaff.stream.common").identity
local filter = {}
local uv = vim.loop
filter.__index = filter

function filter:stop()
  close(self.input_stream)
  close(self.output_stream)
  if self.handle then
    self.handle:kill("SIGTERM")
  end
end

function filter:start_fun()
  self.input:start()

  uv.read_start(self.input_stream, function(_, data)
    if data then
      for line in vim.gsplit(data, "\n", true) do
        if line ~= "" then
          self.output_stream:write(self.filter(line) .. "\n")
        end
      end
    else
      close(self.output_stream)
    end
  end)
end

function filter:start_cmd()
  self.handle = uv.spawn(self.command, {
    args = self.args,
    stdio = { self.input_stream, self.output_stream, nil },
  }, function()
    close(self.input_stream)
    close(self.output_stream)
    close(self.handle)
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
