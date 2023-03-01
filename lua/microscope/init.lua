local results = require("microscope.results")
local preview = require("microscope.preview")
local input = require("microscope.input")
local stream = require("microscope.stream")
local microscope = {}
microscope.__index = microscope

local function absolute(size)
  local ui = vim.api.nvim_list_uis()[1]
  return {
    relative = "editor",
    width = size.width,
    height = size.height,
    col = (ui.width / 2) - (size.width / 2),
    row = (ui.height / 2) - (size.height / 2),
    style = "minimal",
    border = "rounded",
  }
end

local function relative(size, opts)
  local config = absolute(size)
  config.col = config.col + opts.x
  config.row = config.row + opts.y
  config.width = opts.width
  config.height = opts.height
  return config
end

local function generate_layout(size)
  local input_height = 1
  local results_offset = 3
  local results_height = size.height - results_offset

  local input_opts = relative(size, {
    x = 0,
    y = 0,
    width = size.width / 2 - 2,
    height = input_height,
  })
  local results_opts = relative(size, {
    x = 0,
    y = results_offset,
    width = size.width / 2 - 2,
    height = results_height,
  })
  local preview_opts = relative(size, {
    x = size.width / 2,
    y = 0,
    width = size.width / 2,
    height = size.height,
  })
  return {
    input = input_opts,
    results = results_opts,
    preview = preview_opts,
  }
end

function microscope:bind_action(fun)
  return function()
    pcall(fun, self)
  end
end

function microscope:focus_previous()
  vim.api.nvim_set_current_win(self.old_win)
  vim.api.nvim_set_current_buf(self.old_buf)
end

function microscope:close()
  self.input:close()
  self.results:close()
  self.preview:close()
end

function microscope:show_preview()
  self.preview:show(self.results:selected())
end

function microscope:finder(opts)
  return function()
    local chain_fn = opts.chain
    local open_fn = opts.open
    local preview_fn = opts.preview

    local layout = generate_layout(self.size)

    self.old_win = vim.api.nvim_get_current_win()
    self.old_buf = vim.api.nvim_get_current_buf()

    self.results = results.new(layout.results, function(data)
      self:close()
      self:focus_previous()
      open_fn(data, self.old_win, self.old_buf)
    end)
    self.preview = preview.new(layout.preview, preview_fn)
    self.input = input.new(layout.input)

    local find
    local function cb()
      if find then
        self.results:on_new()
        find:stop()
      end
      local search_text = self.input:text()
      find = stream.chain(chain_fn(search_text), function(v, parser)
        self.results:on_data(v, parser)
        vim.schedule(function()
          self:show_preview()
        end)
      end)
      find:start()
    end

    self.input:on_edit(cb)

    for lhs, action in pairs(self.bindings) do
      vim.keymap.set("i", lhs, self:bind_action(action), { buffer = self.input.buf })
    end
  end
end

function microscope.setup(opts)
  local v = setmetatable({ keys = {} }, microscope)

  v.size = opts.size
  v.bindings = opts.bindings

  return v
end

return microscope
