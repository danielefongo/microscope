local M = {}

function M.ls()
  return vim.split(vim.fn.system("ls"), "\n", { trimempty = true })
end

return M
