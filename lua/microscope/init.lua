local results = require("microscope.results")
local preview = require("microscope.preview")
local input = require("microscope.input")
local stream = require("microscope.stream")
local shape = require("microscope.shape")
local microscope = {}
microscope.__index = microscope

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
  if self.has_preview then
    self.preview:close()
  end
  vim.api.nvim_del_autocmd(self.vim_resize)
  vim.api.nvim_del_autocmd(self.input_leave)
end

function microscope:show_preview()
  local selected = self.results:selected()
  if selected then
    self.preview:show(selected)
  end
end

function microscope:update()
  local layout = shape.generate(self.size, self.has_preview)
  self.results:update(layout.results)
  if self.has_preview then
    self.preview:update(layout.preview)
  end
  self.input:update(layout.input)
end

function microscope:finder(opts)
  return function()
    local chain_fn = opts.chain
    local open_fn = opts.open
    local preview_fn = opts.preview

    self.has_preview = preview_fn ~= nil

    local layout = shape.generate(self.size, self.has_preview)

    self.old_win = vim.api.nvim_get_current_win()
    self.old_buf = vim.api.nvim_get_current_buf()

    self.results = results.new(layout.results, function(data)
      self:focus_previous()
      open_fn(data, self.old_win, self.old_buf)
    end)
    if self.has_preview then
      self.preview = preview.new(layout.preview, preview_fn)
    end
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

        if self.has_preview then
          vim.schedule(function()
            self:show_preview()
          end)
        end
      end)
      find:start()
    end

    self.input:on_edit(cb)

    self.vim_resize = vim.api.nvim_create_autocmd("VimResized", {
      callback = function()
        self:update()
      end,
    })
    self.input_leave = vim.api.nvim_create_autocmd("BufLeave", {
      buffer = self.input.buf,
      callback = function()
        self:close()
      end,
    })

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
