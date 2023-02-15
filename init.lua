local actions = require("yaff.actions")

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

function _G.n_menu()
  local rows = { "test1", "test2", "test3" }
  local width = 5
  local height = 3

  local buf = vim.api.nvim_create_buf(false, true)
  local ui = vim.api.nvim_list_uis()[1]

  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = (ui.width / 2) - (width / 2),
    row = (ui.height / 2) - (height / 2),
    style = "minimal",
    border = "rounded",
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  vim.api.nvim_buf_set_lines(buf, 0, 1, true, rows)
  vim.api.nvim_win_set_cursor(win, { 1, 0 })

  for lhs, action in pairs(bindings) do
    vim.keymap.set("n", lhs, bind_action(win, action), { buffer = buf, desc = "vim.lsp.buf.hover" })
  end
end
