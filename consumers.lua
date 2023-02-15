local M = {}

function M.fzf(input, text)
  if text and text ~= "" then
    return vim.split(vim.fn.system(string.format('fzf --filter "%s"', text), input), "\n", { trimempty = true })
  else
    return input
  end
end

return M
