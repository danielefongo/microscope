local files = {}

function files.rg()
  return {
    command = "rg",
    args = { "--files", "--color", "never" },
    parser = function(data)
      return {
        text = data.text,
        file = data.text,
      }
    end,
  }
end

function files.cat(text)
  return {
    command = "cat",
    args = { text },
  }
end

function files.vimgrep(text)
  return {
    command = "rg",
    args = { "--vimgrep", "-M", 200, text },
    parser = function(data)
      local elements = vim.split(data.text, ":", {})

      return {
        text = data.text,
        file = elements[1],
        row = tonumber(elements[2]),
        col = tonumber(elements[3]),
      }
    end,
  }
end

function files.fzf(text)
  return {
    command = "fzf",
    args = { "--filter", text },
  }
end

return files
