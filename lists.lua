local M = {}

function M.rg()
  return {
    command = "rg",
    args = { "--line-buffered", "--files" },
  }
end

function M.fzf(text)
  return {
    command = "fzf",
    args = { "--filter", text },
  }
end

function M.head(lines)
  return {
    command = "head",
    args = { "-n", lines },
  }
end

return M
