local helpers = require("tests.helpers")
local finder = require("microscope.finder")
local input = require("microscope.ui.input")

local user = {}
user.__index = user

-- actions

function user:focus(window)
  helpers.focus(self.finder[window])
  helpers.wait(50)
end

function user:search(text)
  self:focus_input()

  self:keystroke(text, "i")
end

function user:keystroke(text, mode)
  if mode == "i" or mode == "a" then
    helpers.feed(mode .. text, "x")
  else
    helpers.feed(text, mode)
  end
  helpers.wait(50)
end

function user:close_finder()
  self.finder:close()
  helpers.wait(50)
end

function user:resumes_finder()
  self.finder:resume()
end

-- assertions

function user:does_not_see_window(window)
  assert.is.Nil(self.finder[window].win)
end

function user:sees_window(window, layout)
  assert.is_not.Nil(self.finder[window].win)
  if layout then
    assert.are.same(self.finder[window].layout, layout)
  end
end

function user:sees_text_in(window, lines)
  local win = window
  if type(window) == "string" then
    win = self.finder[window]:get_win()
  end

  assert.is_not.Nil(win)
  local buf = vim.api.nvim_win_get_buf(win)
  assert.are.same(vim.api.nvim_buf_get_lines(buf, 0, -1, false), lines)
end

function user:sees_focused_line_in(window, line)
  local win = window
  if type(window) == "string" then
    win = self.finder[window]:get_win()
  end
  assert.is_not.Nil(win)

  local cursor = vim.api.nvim_win_get_cursor(win)

  local buf = vim.api.nvim_win_get_buf(win)
  assert.are.same(vim.api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], false)[1], line)
end

-- initialization

function user.open_finder(finder_spec)
  local self = setmetatable({}, user)

  local default_opts = {
    prompt = input.default_prompt,
    spinner = input.default_spinner,
    size = { width = 50, height = 50 },
    bindings = {},
  }

  self.finder = finder.new(vim.tbl_deep_extend("force", default_opts, finder_spec))
  return self
end

function user.set_finder(finder_instance)
  local self = setmetatable({}, user)
  self.finder = finder_instance
  return self
end

return user
