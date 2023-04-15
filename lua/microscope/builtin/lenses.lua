local lenses = {}

function lenses.fzf(...)
  return {
    fun = function(flow, request)
      flow.spawn({
        cmd = "fzf",
        args = { "-f", request.text },
      })
    end,
    inputs = { ... },
  }
end

function lenses.head(lines, ...)
  return {
    fun = function(flow, _)
      local results = {}
      for array in flow.read_array_iter() do
        for _, element in pairs(array) do
          table.insert(results, element)
          if #results == lines then
            flow.write(results)
            flow.stop()
          end
        end
      end
      if not flow.stopped() then
        flow.write(results)
      end
    end,
    inputs = { ... },
  }
end

return lenses
