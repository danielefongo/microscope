local stream = {}
stream.__index = stream

local input = require("microscope.stream.input")
local filter = require("microscope.stream.filter")
local output = require("microscope.stream.output")

function stream.chain(list_of_opts, cb)
  local s = nil
  for idx, opts in ipairs(list_of_opts) do
    if idx == 1 then
      s = input.new(opts)
    else
      s = filter.new(s, opts)
    end
  end
  s = output.new(s, cb)
  return s
end

return stream
