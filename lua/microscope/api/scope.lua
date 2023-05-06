local uv = vim.loop
local lens = require("microscope.api.lens")
local scope = {}
scope.__index = scope

function scope:stop()
  if self.idle then
    self.idle:stop()
    self.lens:stop()

    local flushed = ""
    while flushed == "" do
      flushed = self.lens:read()
    end
  end
end

function scope:search(request)
  self:stop()
  self.request = request

  local output = ""

  self.lens:feed(request)

  self.idle = uv.new_idle()
  self.idle:start(function()
    local text = self.lens:read()

    if type(text) == "string" and text ~= "" then
      output = output .. text
    end

    if text == nil then
      self.lens:stop()

      vim.schedule(function()
        local parsed = {}

        if output:sub(-1) == "\n" then
          output = output:sub(1, -2)
        end

        if output == "" then
          return self.callback({}, request)
        end

        for value in vim.gsplit(output, "\n") do
          table.insert(parsed, self.parser(value, request))
        end
        output = ""

        self.callback(parsed, request)
      end)

      self.idle:stop()
    end
  end)
end

function scope.new(opts)
  local s = setmetatable({}, scope)

  opts = opts or {}

  s.lens = lens.new(opts.lens)
  s.parser = opts.parser or function(x)
    return x
  end
  s.callback = opts.callback or function() end

  return s
end

return scope
