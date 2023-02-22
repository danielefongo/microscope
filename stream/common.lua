local common = {}
common.__index = common

function common.close(handle)
  if handle and not handle:is_closing() then
    handle:close()
  end
end

return common
