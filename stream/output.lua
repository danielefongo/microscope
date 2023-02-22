local close = require("yaff.stream.common").close
local output = {}
local uv = vim.loop
output.__index = output

function output:stop()
  if self.handle then
    close(self.input_stream)
    close(self.output_stream)
    self.handle:kill("SIGTERM")
  end
end

function output:start()
  local output_data = ""

  self.handle = uv.spawn(self.command, {
    args = self.args,
    stdio = { self.input_stream, self.output_stream, nil },
  }, function()
    self.cb(vim.split(output_data, "\n", { trimempty = true }))

    close(self.input_stream)
    close(self.output_stream)
    close(self.handle)
  end)

  uv.read_start(self.output_stream, function(_, data)
    if data then
      output_data = output_data .. data
    end
  end)

  uv.read_start(self.input_stream, function() end)

  self.input:start()
end

function output.new(input, cb)
  local s = setmetatable({ keys = {} }, output)

  s.input = input
  s.input_stream = input and input.output_stream
  s.output_stream = uv.new_pipe(false)

  s.command = "cat"
  s.args = {}
  s.cb = cb

  return s
end

return output
