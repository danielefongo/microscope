local open = {}

function open.file(data, win, _)
  vim.cmd("e " .. data.text)
  if data.row and data.col then
    local cursor = { data.row, data.col }
    vim.api.nvim_win_set_cursor(win, cursor)
  end
end

function open.buffer(data, win, _)
  vim.api.nvim_win_set_buf(win, data.buffer)
end

return open
