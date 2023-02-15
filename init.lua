local actions = require("yaff.actions")
local lists = require("yaff.lists")
local consumers = require("yaff.consumers")

local WIDTH = 30

function _G.bind_action(win, fun)
  return function()
    local opts = {
      win = win,
      buf = vim.api.nvim_win_get_buf(win),
    }
    pcall(fun, opts)
  end
end

local bindings = {
  ["<c-j>"] = actions.next,
  ["<c-k>"] = actions.previous,
  ["<Tab>"] = actions.select,
}

local function spawn_input(on_lines)
  local ui = vim.api.nvim_list_uis()[1]
  local height = 1

  local buf = vim.api.nvim_create_buf(false, true)

  local opts = {
    relative = "editor",
    width = WIDTH,
    height = height,
    col = (ui.width / 2) - (WIDTH / 2),
    row = (ui.height / 2) - (height / 2) - 7,
    style = "minimal",
    border = "rounded",
  }
  local win = vim.api.nvim_open_win(buf, true, opts)

  vim.api.nvim_command("startinsert")

  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      local value = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      local rows = consumers.fzf(lists.ls(), value)
      on_lines(rows)
    end,
  })
  vim.api.nvim_command("startinsert!")

  return { win = win, buf = buf }
end

local function spawn_menu()
  local ui = vim.api.nvim_list_uis()[1]
  local height = 10

  local buf = vim.api.nvim_create_buf(false, true)
  local values = lists.ls()
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, values)

  local opts = {
    relative = "editor",
    width = WIDTH,
    height = height,
    col = (ui.width / 2) - (WIDTH / 2),
    row = (ui.height / 2) - (height / 2),
    style = "minimal",
    border = "rounded",
  }

  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_option(win, "cursorline", true)

  return { win = win, buf = buf }
end

function _G.n_menu()
  local menu = spawn_menu()
  local input = spawn_input(function(values)
    vim.schedule(function()
      vim.api.nvim_buf_set_lines(menu.buf, 0, -1, true, values)
    end)
  end)

  for lhs, action in pairs(bindings) do
    vim.keymap.set("i", lhs, bind_action(menu.win, action), { buffer = input.buf })
  end
end
