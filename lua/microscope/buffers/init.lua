local buffers = {}

function buffers.open(data, win, _)
  vim.api.nvim_win_set_buf(win, data.buffer)
end

function buffers.preview(data, window)
  window:set_buf(data.buffer)
end

buffers.lists = require("microscope.buffers.lists")

return buffers
