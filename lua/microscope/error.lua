local constants = require("microscope.constants")
local events = require("microscope.events")
local error = {}

local function command_args_to_string(command, args)
  return string.format("%s %s", command, table.concat(args, " ")):gsub("^(%s*.-)%s*$", "%1")
end

function error.generic(message)
  events.fire(constants.event.error, { message = message })
end

function error.command_not_found(command, args)
  local command_args = command_args_to_string(command, args)
  error.generic(string.format('microscope: command "%s" not found.', command_args))
end

function error.command_failed(command, args, data)
  local command_args = command_args_to_string(command, args)
  error.generic(string.format('microscope: command "%s" failed.\n%s', command_args, data))
end

function error.show(data)
  vim.defer_fn(function()
    vim.api.nvim_err_write(data.message .. "\n")
  end, 10)
end

return error
