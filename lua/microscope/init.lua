local finder = require("microscope.finder")
local microscope = {}
microscope.opts = {}
microscope.finders = {}
microscope.__index = microscope

function microscope:__call()
  finder.new(vim.tbl_deep_extend("force", microscope.opts, self.opts))
end

function microscope:override(opts)
  self.opts = vim.tbl_deep_extend("force", self.opts, opts)
end

function microscope.finder(opts)
  local self = setmetatable({ keys = {} }, microscope)
  self.opts = vim.tbl_deep_extend("force", microscope.opts, opts)
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
