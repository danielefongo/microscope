local M = {}

function M.rg(cb)
  return {
    command = "rg",
    args = { "--line-buffered", "--files" },
    cb = cb,
  }
end

function M.fzf(text, cb)
  return {
    command = "fzf",
    args = { "--filter", text },
    cb = cb,
  }
end

function M.head(lines, cb)
  return {
    command = "head",
    args = { "--lines", lines },
    cb = cb,
  }
end

return M
