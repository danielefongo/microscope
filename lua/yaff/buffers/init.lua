local buffers = {}

function buffers.open(data, win, _)
  vim.api.nvim_win_set_buf(win, data.buffer)
end

function buffers.preview(data, win, _)
  vim.schedule(function()
    vim.api.nvim_win_set_buf(win, data.buffer)
  end)
end

buffers.lists = require("yaff.buffers.lists")

return buffers
