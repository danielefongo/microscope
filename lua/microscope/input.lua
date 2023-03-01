local input = {}
input.__index = input

function input:text()
  return string.sub(vim.api.nvim_buf_get_lines(self.buf, 0, 1, false)[1], 3)
end

function input:on_edit(cb)
  vim.api.nvim_buf_attach(self.buf, false, {
    on_lines = cb,
  })
end

function input:close()
  vim.api.nvim_buf_delete(self.buf, { force = true })
end

function input:update(opts)
  vim.api.nvim_win_set_config(self.win, opts)

  vim.api.nvim_buf_set_option(self.buf, "buftype", "prompt")
  vim.fn.prompt_setprompt(self.buf, "> ")
  vim.api.nvim_command("startinsert")
end

function input.new(opts)
  local v = setmetatable({ keys = {} }, input)

  v.buf = vim.api.nvim_create_buf(false, true)
  v.win = vim.api.nvim_open_win(v.buf, true, opts)

  v:update(opts)
  return v
end

return input
