local uv = vim.loop
local lens = require("microscope.api.lens")
local error = require("microscope.api.error")
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

function scope:search(request, args)
  self:stop()
  self.request = request

  local output = ""

  self.lens:feed(request)

  local new_args, defaults = self.lens:set_args(args)
  if not new_args then
    error.critical(
      string.format(
        "microscope: invalid arguments types\nprovided: %s\ndefaults: %s",
        vim.inspect(args),
        vim.inspect(defaults)
      )
    )
  end

  self.idle = uv.new_idle()
  self.idle:start(function()
    local text = self.lens:read()

    if type(text) == "string" and text ~= "" then
      output = output .. text
    end

    if text == nil then
      self.lens:stop()

      vim.schedule(function()
        if output:sub(-1) == "\n" then
          output = output:sub(1, -2)
        end

        if output == "" then
          return self.callback({}, request)
        end

        local data = vim.split(output, "\n")
        output = ""

        self.callback(data, request)
      end)

      self.idle:stop()
    end
  end)
end

function scope.new(opts)
  local s = setmetatable({}, scope)

  opts = opts or {}

  s.lens = lens.new(opts.lens)
  s.callback = opts.callback or function() end

  return s
end

return scope
