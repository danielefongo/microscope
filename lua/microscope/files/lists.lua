local M = {}

function M.rg()
  return {
    command = "rg",
    args = { "--line-buffered", "--files" },
  }
end

function M.cat(text)
  return {
    command = "cat",
    args = { text },
  }
end

function M.vimgrep(text)
  return {
    command = "rg",
    args = { "--line-buffered", "--vimgrep", "-M", 200, text },
    parser = function(data)
      local elements = vim.split(data.text, ":", {})

      return {
        text = elements[1],
        row = tonumber(elements[2]),
        col = tonumber(elements[3]),
      }
    end,
  }
end

function M.fzf(text)
  return {
    command = "fzf",
    args = { "--filter", text },
  }
end

return M
