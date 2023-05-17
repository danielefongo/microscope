local box = require("microscope.api.experimental.box")
local error = require("microscope.api.error")
local events = require("microscope.events")
local layout = {}

local layouts = {
  horizontal = function()
    return box.horizontal({
      box.vertical({ box.input(1), box.results() }, "50%"),
      box.preview(),
    })
  end,
  vertical_no_preview = function()
    return box.vertical({ box.input(1), box.results() })
  end,
  vertical = function()
    return box.vertical({ box.input(1), box.results(), box.preview() })
  end,
}

local OFFSET = 2

local function validate_rectangle(rectangle, reference_rectangle)
  return rectangle.col >= reference_rectangle.col
    and rectangle.col + rectangle.width <= reference_rectangle.col + reference_rectangle.width
    and rectangle.row >= reference_rectangle.row
    and rectangle.row + rectangle.height <= reference_rectangle.row + reference_rectangle.height
    and rectangle.height > 0
    and rectangle.width > 0
end

local function generate_rectangle(size)
  local ui = vim.api.nvim_list_uis()[1]
  return {
    relative = "editor",
    width = size.width,
    height = size.height,
    col = (ui.width / 2) - (size.width / 2) - 1,
    row = (ui.height / 2) - (size.height / 2) - 1,
    style = "minimal",
    border = "rounded",
  }
end

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
  if size == "fill" then
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
    if element.size == "fill" then
      number_of_fills = number_of_fills + 1
    else
      other_elements_size = other_elements_size + calculate_size(element.size, size)
    end
  end

  return (size - other_elements_size - (#elements - 1) * 2) / number_of_fills
end

local function build_box(build, spec, rectangle, axis, axis_dimension)
  local previous_size = 0

  local fill_size = calculate_fill_size(spec.box.elements, rectangle[axis_dimension])

  for _, element in pairs(spec.box.elements) do
    local element_size = calculate_size(element.size, rectangle[axis_dimension], fill_size)
    local element_rectangle = relative_rectangle(rectangle, { [axis] = previous_size, [axis_dimension] = element_size })

    layout.gen(build, element_rectangle, element)

    previous_size = previous_size + element_size + OFFSET
  end

  return build
end

function layout.gen(build, rectangle, spec)
  if spec.type == "box" then
    if spec.box.direction == "vertical" then
      return build_box(build, spec, rectangle, "y", "height")
    elseif spec.box.direction == "horizontal" then
      return build_box(build, spec, rectangle, "x", "width")
    end
  elseif spec.type ~= "dummy" then
    build[spec.type] = rectangle
  end
end

function layout.generate(layout_size, has_preview)
  local ui = vim.api.nvim_list_uis()[1]

  local layout_rectangle = generate_rectangle({
    width = math.min(layout_size.width, ui.width - 4),
    height = math.min(layout_size.height, ui.height - 4),
  })

  local build = {}
  if not has_preview then
    layout.gen(build, layout_rectangle, layouts.vertical_no_preview())
  else
    if ui.width < layout_size.width then
      layout.gen(build, layout_rectangle, layouts.vertical())
    else
      layout.gen(build, layout_rectangle, layouts.horizontal())
    end
  end

  for _, value in pairs(build) do
    if not validate_rectangle(value, layout_rectangle) then
      error.critical("microscope: cannot be rendered")
      return
    end
  end

  events.fire(events.event.layout_updated, build)
end

return layout
