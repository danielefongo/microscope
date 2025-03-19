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

  local segments = {}
  local i = 1

  while i <= #self.highlights do
    local hl = self.highlights[i]

    if from <= hl.to and to >= hl.from then
      table.remove(self.highlights, i)

      if hl.from < from then
        table.insert(segments, {
          from = hl.from,
          to = from - 1,
          color = hl.color,
        })
      end

      if hl.to > to then
        table.insert(segments, {
          from = to + 1,
          to = hl.to,
          color = hl.color,
        })
      end
    else
      i = i + 1
    end
  end

  table.insert(segments, {
    from = from,
    to = to,
    color = color,
  })

  for _, segment in ipairs(segments) do
    table.insert(self.highlights, segment)
  end

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

function highlight:hl_match_with(highlight_fun, pattern, group)
  local tuple = { string.match(self.text, pattern) }

  if type(tuple[group]) ~= "string" then
    return self
  end

  local start_pos = 0
  for i = 1, group - 1, 1 do
    if tuple[i] then
      start_pos = start_pos + #tuple[i]
    end
  end

  local text_to_highlight = tuple[group]
  local highlights = highlight_fun(text_to_highlight)
  if highlights then
    for row, row_highlights in pairs(highlights) do
      for _, hl in ipairs(row_highlights) do
        local from = start_pos + hl.from
        local to = start_pos + hl.to
        self:hl(hl.color, from, to)
      end
    end
  end
  return self
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
