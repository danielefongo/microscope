local uv = vim.loop
local lens = require("microscope.api.lens")
local error = require("microscope.api.error")
local scope = {}
scope.__index = scope

function scope:stop()
  if self.stopped then
    return
  end
  self.stopped = true

  if self.idle then
    self.idle:stop()
    self.lens:stop()
    pcall(function()
      vim.wait(150, function()
        return not vim.loop.is_active(self.idle)
      end, 5)
    end)
    self.idle = nil
  end

  self.lines = nil
end

function scope:search(request, args)
  self:stop()
  self.request = request

  self.lens:feed(request)
  self.stopped = false

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

  self.lines = setmetatable({}, { __mode = "v" })

  self.idle = uv.new_idle()
  self.idle:start(function()
    local text = self.lens:read()

    if type(text) == "string" and text ~= "" then
      for line in vim.gsplit(text, "\n", { plain = true, trimempty = true }) do
        table.insert(self.lines, line)
      end
    end

    if text == nil then
      local lines = vim.deepcopy(self.lines)
      self:stop()
      vim.schedule(function()
        self.callback(lines, request)
      end)
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
