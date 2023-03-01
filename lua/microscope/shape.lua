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

local function horizontal(size)
  local input_height = 1
  local results_offset = 3
  local results_height = size.height - results_offset

  local input_opts = relative(size, {
    x = 0,
    y = 0,
    width = size.width / 2 - 2,
    height = input_height,
  })
  local results_opts = relative(size, {
    x = 0,
    y = results_offset,
    width = size.width / 2 - 2,
    height = results_height,
  })
  local preview_opts = relative(size, {
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

local function vertical(size)
  local width = vim.api.nvim_list_uis()[1].width

  local input_height = 1
  local input_offset = input_height + 2
  local rest_height = size.height - input_offset
  local results_height = math.floor(rest_height / 2) + 1
  local results_offset = input_offset + results_height + 2
  local preview_height = size.height - input_height - results_height

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
  local preview_opts = relative(size, {
    x = 0,
    y = results_offset,
    width = width,
    height = preview_height,
  })
  return {
    input = input_opts,
    results = results_opts,
    preview = preview_opts,
  }
end

function shape.generate(size)
  local ui = vim.api.nvim_list_uis()[1]
  if ui.width < size.width then
    return vertical(size)
  else
    return horizontal(size)
  end
end

return shape
