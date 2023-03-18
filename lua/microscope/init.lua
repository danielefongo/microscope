local finder = require("microscope.finder")
local microscope = {}
microscope.opts = {}
microscope.finders = {}

function microscope:__call()
  finder.new(microscope.opts, self.opts)
end

function microscope.finder(opts)
  local self = setmetatable({ keys = {} }, microscope)
  self.opts = opts
  return self
end

function microscope.setup(opts)
  microscope.opts.size = opts.size
  microscope.opts.bindings = opts.bindings

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
