local actions = require("yaff.actions")
local lists = require("yaff.lists")
local stream = require("yaff.stream")

local WIDTH = 50

local function chain(text, cb)
  return stream.chain({
    lists.rg(),
    lists.fzf(text),
    lists.head(10, cb),
  })
end

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

local function spawn_input(on_new, on_lines)
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

  local find
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      if find then
        find:stop()
        on_new()
      end
      local search_text = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      find = chain(search_text, on_lines)
      find:start()
    end,
  })

  return { win = win, buf = buf }
end

local function spawn_menu()
  local ui = vim.api.nvim_list_uis()[1]
  local height = 10

  local buf = vim.api.nvim_create_buf(false, true)

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
  local input = spawn_input(function()
    vim.schedule(function()
      vim.api.nvim_buf_set_lines(menu.buf, 0, -1, true, {})
    end)
  end, function(value)
    vim.schedule(function()
      if vim.api.nvim_buf_get_lines(menu.buf, 0, 1, true)[1] == "" then
        vim.api.nvim_buf_set_lines(menu.buf, 0, -1, true, { value })
      else
        vim.api.nvim_buf_set_lines(menu.buf, -1, -1, true, { value })
      end
    end)
  end)

  for lhs, action in pairs(bindings) do
    vim.keymap.set("i", lhs, bind_action(menu.win, action), { buffer = input.buf })
  end
end
