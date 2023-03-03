local common = {}
common.__index = common

function common.close(handle)
  if handle and not handle:is_closing() then
    pcall(function()
      handle:read_stop()
    end)
    handle:close()
  end
end

function common.identity(x)
  return x
end

return common
