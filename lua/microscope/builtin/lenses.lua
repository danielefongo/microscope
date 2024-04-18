local lenses = {}

function lenses.fzf(...)
  return {
    fun = function(flow, request)
      flow.cmd.iter(flow.read_iter()):pipe("fzf", { "-f", request.text }):into(flow)
    end,
    inputs = { ... },
  }
end

function lenses.head(...)
  return {
    fun = function(flow, _, args)
      local results = {}
      for array in flow.read_array_iter() do
        for _, element in pairs(array) do
          table.insert(results, element)
          if #results == args.limit then
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
    args = {
      limit = 5000,
    },
  }
end

function lenses.cache(...)
  return {
    fun = function(flow, _, _, context)
      if context and context.cache then
        return flow.write(context.cache)
      end

      local cache = ""
      flow.cmd
        .iter(flow.read_iter())
        :filter(function(lines)
          cache = cache .. lines
          return lines
        end)
        :into(flow)

      if not flow.stopped() then
        context.cache = cache
      end
    end,
    inputs = { ... },
  }
end

function lenses.write(data)
  return {
    fun = function(flow)
      flow.write(data)
    end,
  }
end

return lenses
