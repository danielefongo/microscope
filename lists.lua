local M = {}

function M.rg()
  return {
    command = "rg",
    args = { "--line-buffered", "--files" },
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

function M.buffers()
  return {
    fun = function()
      local bufs = {}
      local buf_ids = vim.api.nvim_list_bufs()
      for _, id in ipairs(buf_ids) do
        if vim.fn.buflisted(id) == 1 then
          table.insert(bufs, id .. ": " .. vim.api.nvim_buf_get_name(id))
        end
      end
      return bufs
    end,
    parser = function(data)
      local elements = vim.split(data.text, ":", {})

      return {
        text = elements[2],
        buffer = tonumber(elements[1]) + 0,
      }
    end,
  }
end

function M.head(lines)
  return {
    command = "head",
    args = { "-n", lines },
  }
end

return M
