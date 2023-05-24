local display = {}
display.__index = display

local OFFSET = 2

local function relative_rectangle(rectangle, opts)
  return {
    relative = "editor",
    width = opts.width or rectangle.width,
    height = opts.height or rectangle.height,
    col = rectangle.col + (opts.x or 0),
    row = rectangle.row + (opts.y or 0),
    style = "minimal",
    border = "rounded",
  }
end

local function calculate_size(size, container_size, fill_size)
  if not size then
    return math.floor(fill_size)
  elseif type(size) == "string" and size:sub(-1) == "%" then
    return math.floor(container_size / 100 * tonumber(size:sub(0, -2)) - 1)
  else
    return size
  end
end

local function calculate_fill_size(elements, size)
  local number_of_fills = 0
  local other_elements_size = 0

  for _, element in pairs(elements) do
    if not element.size then
      number_of_fills = number_of_fills + 1
    else
      other_elements_size = other_elements_size + calculate_size(element.size, size)
    end
  end

  return (size - other_elements_size - (#elements - 1) * 2) / number_of_fills
end

local function build_box(rectangle, build, spec, axis, axis_dimension)
  local previous_size = 0

  local fill_size = calculate_fill_size(spec.box.elements, rectangle[axis_dimension])

  for _, element in pairs(spec.box.elements) do
    local element_size = calculate_size(element.size, rectangle[axis_dimension], fill_size)
    local element_rectangle = relative_rectangle(rectangle, { [axis] = previous_size, [axis_dimension] = element_size })

    element:gen(element_rectangle, build)

    previous_size = previous_size + element_size + OFFSET
  end
end

function display:gen(rectangle, build)
  if self.type == "box" then
    if self.box.direction == "vertical" then
      build_box(rectangle, build, self, "y", "height")
    elseif self.box.direction == "horizontal" then
      build_box(rectangle, build, self, "x", "width")
    end
  elseif self.type ~= "space" then
    build[self.type] = rectangle
  end
end

function display:build(rectangle)
  local build = {}
  display.vertical({ self }):gen(rectangle, build)
  return build
end

function display.vertical(elements, size)
  return setmetatable({
    type = "box",
    size = size,
    box = { direction = "vertical", elements = elements },
  }, display)
end

function display.horizontal(elements, size)
  return setmetatable({
    type = "box",
    size = size,
    box = { direction = "horizontal", elements = elements },
  }, display)
end

function display.input(size)
  return setmetatable({ type = "input", size = size or 1 }, display)
end

function display.results(size)
  return setmetatable({ type = "results", size = size }, display)
end

function display.preview(size)
  return setmetatable({ type = "preview", size = size }, display)
end

function display.space(size)
  if type(size) == "number" then
    size = size - 2
  end
  return setmetatable({ type = "space", size = size }, display)
end

return display
