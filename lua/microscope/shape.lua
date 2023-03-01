local shape = {}

local function absolute(size)
  local ui = vim.api.nvim_list_uis()[1]
  return {
    relative = "editor",
    width = size.width,
    height = size.height,
    col = (ui.width / 2) - (size.width / 2),
    row = (ui.height / 2) - (size.height / 2),
    style = "minimal",
    border = "rounded",
  }
end

local function relative(size, opts)
  local config = absolute(size)
  config.col = config.col + opts.x
  config.row = config.row + opts.y
  config.width = opts.width
  config.height = opts.height
  return config
end

local function horizontal(size, has_preview)
  local input_height = 1
  local input_offset = input_height + 2
  local results_height = size.height - input_offset
  local left_width = (has_preview and size.width / 2 - 2) or size.width

  local input_opts = relative(size, {
    x = 0,
    y = 0,
    width = left_width,
    height = input_height,
  })
  local results_opts = relative(size, {
    x = 0,
    y = input_offset,
    width = left_width,
    height = results_height,
  })
  local preview_opts = has_preview
    and relative(size, {
      x = size.width / 2,
      y = 0,
      width = size.width / 2,
      height = size.height,
    })
  return {
    input = input_opts,
    results = results_opts,
    preview = preview_opts,
  }
end

local function vertical(size, has_preview)
  local width = vim.api.nvim_list_uis()[1].width

  local input_height = 1
  local input_offset = input_height + 2
  local rest_height = size.height - input_offset
  local results_height = (has_preview and math.floor(rest_height / 2) + 1) or rest_height

  local input_opts = relative(size, {
    x = 0,
    y = 0,
    width = width,
    height = input_height,
  })
  local results_opts = relative(size, {
    x = 0,
    y = input_offset,
    width = width,
    height = results_height,
  })
  local preview_opts = has_preview
    and relative(size, {
      x = 0,
      y = input_offset + results_height + 2,
      width = width,
      height = size.height - input_height - results_height,
    })
  return {
    input = input_opts,
    results = results_opts,
    preview = preview_opts,
  }
end

function shape.generate(size, has_preview)
  local ui = vim.api.nvim_list_uis()[1]
  if ui.width < size.width then
    return vertical(size, has_preview)
  else
    return horizontal(size, has_preview)
  end
end

return shape
