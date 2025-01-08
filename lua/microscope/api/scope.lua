local uv = vim.loop
local lens = require("microscope.api.lens")
local error = require("microscope.api.error")
local scope = {}
scope.__index = scope

function scope:stop()
  if self.idle then
    self.idle:stop()
    self.lens:stop()

    self.idle = nil
  end
end

function scope:search(request, args)
  self:stop()
  self.request = request

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

  local lines = {}

  self.idle = uv.new_idle()
  self.idle:start(function()
    local text = self.lens:read()

    if type(text) == "string" and text ~= "" then
      for line in vim.gsplit(text, "\n", { plain = true, trimempty = true }) do
        table.insert(lines, line)
      end
    end

    if text == nil then
      self.lens:stop()

      vim.schedule(function()
        self.callback(lines, request)
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
