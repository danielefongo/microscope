local files = {}

local function relative_path(filename)
  return string.gsub(filename, vim.fn.getcwd() .. "/", "")
end

function files.rg()
  return {
    command = "rg",
    args = { "--files", "--color", "never" },
    parser = function(data)
      return {
        text = relative_path(data.text),
        file = data.text,
      }
    end,
  }
end

function files.old_files()
  return {
    fun = function(on_data)
      on_data(vim.v.oldfiles)
    end,
    parser = function(data)
      return {
        text = relative_path(data.text),
        file = data.text,
      }
    end,
  }
end

function files.vimgrep(text)
  return {
    command = "rg",
    args = { "--vimgrep", "-M", 200, text },
    parser = function(data)
      local elements = vim.split(data.text, ":", {})

      return {
        text = relative_path(data.text),
        file = elements[1],
        row = tonumber(elements[2]),
        col = tonumber(elements[3]),
      }
    end,
  }
end

function files.buffergrep(text, filename)
  return {
    command = "rg",
    args = { "--vimgrep", "-M", 200, text, filename },
    parser = function(data)
      local elements = vim.split(data.text, ":", {})

      return {
        text = string.format("%s:%s: %s", elements[2], elements[3], elements[4]),
        file = elements[1],
        row = tonumber(elements[2]),
        col = tonumber(elements[3]),
      }
    end,
  }
end

return files
