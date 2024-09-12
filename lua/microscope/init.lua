local finder = require("microscope.finder")
local instance = require("microscope.instance")
local microscope = {}
microscope.opts = {}
microscope.finders = {}
microscope.__index = microscope

function microscope:__call(opts)
  return finder.new(vim.tbl_deep_extend("force", microscope.opts, self.opts, opts or {}))
end

function microscope:bind(opts)
  return function()
    self(opts)
  end
end

function microscope:override(opts)
  self.opts = vim.tbl_deep_extend("force", self.opts, opts)
  return self
end

function microscope.resume()
  if instance.current then
    instance.current:resume()
  end
end

function microscope.finder(opts)
  local self = setmetatable({}, microscope)
  self.opts = vim.tbl_deep_extend("force", microscope.opts, opts)
  return self
end

function microscope.setup(opts)
  microscope.opts.size = opts.size
  microscope.opts.bindings = opts.bindings or {}
  microscope.opts.prompt = opts.prompt or require("microscope.ui.input").default_prompt
  microscope.opts.spinner = opts.spinner or require("microscope.ui.results").default_spinner
  microscope.opts.layout = opts.layout
  microscope.opts.args = opts.args or {}

  return microscope
end

function microscope.register(finders_opts)
  for name, opts in pairs(finders_opts) do
    if microscope.finders[name] then
      vim.api.nvim_out_write(string.format("microscope: %s overwritten\n", name))
    end
    microscope.finders[name] = microscope.finder(opts)
  end
end

return microscope
