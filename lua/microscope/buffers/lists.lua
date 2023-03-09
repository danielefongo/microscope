local lists = {}

function lists.buffers()
  return {
    fun = function(on_data)
      local bufs = {}
      local buf_ids = vim.api.nvim_list_bufs()
      for _, id in ipairs(buf_ids) do
        if vim.fn.buflisted(id) == 1 then
          table.insert(bufs, id .. ": " .. vim.api.nvim_buf_get_name(id))
        end
      end
      on_data(bufs)
    end,
    parser = function(data)
      local elements = vim.split(data.text, ":", {})

      return {
        text = data.text,
        buffer = tonumber(elements[1]) + 0,
      }
    end,
  }
end

return lists
