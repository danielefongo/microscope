local lists = {}

function lists.fzf(text)
  return {
    command = "fzf",
    args = { "--filter", text },
  }
end

function lists.head(lines)
  return {
    command = "head",
    args = { "-n", lines },
  }
end

return lists
