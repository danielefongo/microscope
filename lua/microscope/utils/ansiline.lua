---@diagnostic disable: cast-local-type

return function(input, truncate_len)
  local valid_chars = 0
  local skipped_chars = 0
  local idx = 1

  local ansi_start = 1
  local ansi_end = 1
  local new_ansi_end

  while true do
    ansi_start, new_ansi_end = string.find(input, "\x1b[[0-9;]*m", idx)
    if ansi_start == nil then
      valid_chars = valid_chars + #input - idx + 1
      break
    elseif ansi_start == 1 then
      skipped_chars = skipped_chars + new_ansi_end - ansi_start + 1
    else
      valid_chars = valid_chars + ansi_start - ansi_end - 1
      if valid_chars > truncate_len then
        break
      end
      skipped_chars = skipped_chars + new_ansi_end - ansi_start + 1
    end
    idx = new_ansi_end + 1
    ansi_end = new_ansi_end
  end
  valid_chars = math.min(valid_chars, truncate_len)
  local new_input = string.sub(input, 1, skipped_chars + valid_chars) .. "\n"

  return string.find(new_input, "\r\n") and new_input or new_input:gsub("\n", "\r\n")
end
