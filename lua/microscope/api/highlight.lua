local highlight = {}
highlight.color = {
  match = "MicroscopeMatch",
  color1 = "MicroscopeColor1",
  color2 = "MicroscopeColor2",
  color3 = "MicroscopeColor3",
  color4 = "MicroscopeColor4",
  color5 = "MicroscopeColor5",
  color6 = "MicroscopeColor6",
}

function highlight:hl(color, from, to)
  to = to or from
  table.insert(self.highlights, {
    from = from,
    to = to,
    color = color,
  })

  return self
end

function highlight:hl_match(color, pattern, group)
  local tuple = { string.match(self.text, pattern) }

  if type(tuple[group]) ~= "string" then
    return self
  end

  for i = 1, group, 1 do
    if not tuple[i] then
      return self
    end
  end

  local reduced_text = self.text
  local count = 1
  for i = 1, group - 1, 1 do
    count = count + #tuple[i]
    reduced_text = pcall(string.gsub, reduced_text, tuple[i], "")
  end

  return self:hl(color, count, count + #tuple[group] - 1)
end

function highlight:get_highlights()
  return self.highlights
end

function highlight.new(highlights, text)
  local h = setmetatable(highlight, { __index = highlight })

  h.highlights = highlights or {}
  h.text = text

  return h
end

return highlight
