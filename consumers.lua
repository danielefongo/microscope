local M = {}

function M.fzf(input, text)
  return vim.split(vim.fn.system(string.format("fzf --filter %s", text), input), "\n", { trimempty = true })
end

return M
