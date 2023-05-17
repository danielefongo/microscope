local box = {}

function box.vertical(elements, size)
  return {
    type = "box",
    size = size or "fill",
    box = { direction = "vertical", elements = elements },
  }
end

function box.horizontal(elements, size)
  return {
    type = "box",
    size = size or "fill",
    box = { direction = "horizontal", elements = elements },
  }
end

function box.input(size)
  return { type = "input", size = size or "fill" }
end

function box.results(size)
  return { type = "results", size = size or "fill" }
end

function box.preview(size)
  return { type = "preview", size = size or "fill" }
end

function box.dummy(size)
  if type(size) == "number" then
    size = size - 2
  end
  return { type = "dummy", size = size or "fill" }
end

return box
