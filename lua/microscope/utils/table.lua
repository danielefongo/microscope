local M = {}

function M.same_types(table, expected)
  for key, value in pairs(table) do
    if expected[key] == nil then
      return true
    end
    if type(value) ~= type(expected[key]) then
      return false
    end
    if type(value) == "table" then
      return M.same_types(value, expected[key])
    end
  end
  return true
end

return M
