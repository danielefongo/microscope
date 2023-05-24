local error = require("microscope.api.error")
local layout = {}

local function validate_rectangle(rectangle, reference_rectangle)
  return rectangle.col >= reference_rectangle.col
    and rectangle.col + rectangle.width <= reference_rectangle.col + reference_rectangle.width
    and rectangle.row >= reference_rectangle.row
    and rectangle.row + rectangle.height <= reference_rectangle.row + reference_rectangle.height
    and rectangle.height > 0
    and rectangle.width > 0
end

local function generate_rectangle(width, height)
  local ui = vim.api.nvim_list_uis()[1]
  return {
    width = width,
    height = height,
    col = (ui.width / 2) - (width / 2) - 1,
    row = (ui.height / 2) - (height / 2) - 1,
  }
end

function layout.generate(finder_size, layout_fn, has_preview)
  local ui = vim.api.nvim_list_uis()[1]

  local finder_rectangle =
    generate_rectangle(math.min(finder_size.width, ui.width - 4), math.min(finder_size.height, ui.height - 4))
  local ui_rectangle = generate_rectangle(ui.width - 4, ui.height - 4)

  local build = layout_fn({
    finder_rectangle = finder_rectangle,
    ui_rectangle = ui_rectangle,
    has_preview = has_preview,
  })

  for _, value in pairs(build) do
    if not validate_rectangle(value, ui_rectangle) then
      error.generic("microscope: cannot be rendered")
      return {}
    end
  end

  return build
end

return layout
