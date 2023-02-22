local stream = {}
stream.__index = stream

local generator = require("yaff.stream.generator")
local filter = require("yaff.stream.filter")
local output = require("yaff.stream.output")

function stream.chain(list_of_opts, cb)
  local s = nil
  for idx, opts in ipairs(list_of_opts) do
    if idx == 1 then
      s = generator.new(opts)
    else
      s = filter.new(s, opts)
    end
  end
  s = output.new(s, cb)
  return s
end

return stream
