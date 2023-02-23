local input = {}
input.__index = input

function input:text()
  return vim.api.nvim_buf_get_lines(self.buf, 0, 1, false)[1]
end

function input:on_edit(cb)
  vim.api.nvim_buf_attach(self.buf, false, {
    on_lines = cb,
  })
end

function input.new(opts)
  local v = setmetatable({ keys = {} }, input)

  v.buf = vim.api.nvim_create_buf(false, true)
  v.win = vim.api.nvim_open_win(v.buf, true, opts)
  vim.api.nvim_buf_set_option(v.buf, "buftype", "prompt")
  vim.fn.prompt_setprompt(v.buf, "> ")

  vim.api.nvim_command("startinsert")

  return v
end

return input
