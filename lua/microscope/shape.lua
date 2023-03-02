local shape = {}

local OFFSET = 2

local function absolute(size)
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
  local results_height = size.height - input_height - OFFSET

  local left_width
  local preview_width
  if has_preview then
    left_width = math.floor(size.width / 2) - OFFSET
    preview_width = size.width - left_width - OFFSET
  else
    left_width = size.width
  end

  local input_opts = relative(size, {
    x = 0,
    y = 0,
    width = left_width,
    height = input_height,
  })
  local results_opts = relative(size, {
    x = 0,
    y = input_height + OFFSET,
    width = left_width,
    height = results_height,
  })
  local preview_opts = has_preview
    and relative(size, {
      x = left_width + OFFSET,
      y = 0,
      width = preview_width,
      height = size.height,
    })
  return {
    input = input_opts,
    results = results_opts,
    preview = preview_opts,
  }
end

local function vertical(size, has_preview)
  local input_height = 1
  local results_height
  local preview_height
  if has_preview then
    results_height = math.floor((size.height - input_height - OFFSET) / 2) - OFFSET
    preview_height = size.height - results_height - input_height - 2 * OFFSET
  else
    results_height = size.height - input_height - OFFSET
  end

  local input_opts = relative(size, {
    x = 0,
    y = 0,
    width = size.width,
    height = input_height,
  })
  local results_opts = relative(size, {
    x = 0,
    y = input_height + OFFSET,
    width = size.width,
    height = results_height,
  })
  local preview_opts = has_preview
    and relative(size, {
      x = 0,
      y = input_height + results_height + 2 * OFFSET,
      width = size.width,
      height = preview_height,
    })
  return {
    input = input_opts,
    results = results_opts,
    preview = preview_opts,
  }
end

function shape.generate(size, has_preview)
  local ui = vim.api.nvim_list_uis()[1]

  local real_size = {
    width = math.min(size.width, ui.width - 4),
    height = math.min(size.height, ui.height - 4),
  }

  if real_size.width <= 16 or real_size.height <= 8 then
    return
  end

  if ui.width < size.width then
    return vertical(real_size, has_preview)
  else
    return horizontal(real_size, has_preview)
  end
end

return shape
