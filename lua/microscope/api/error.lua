local events = require("microscope.events")
local error = {}

function error.generic(message)
  events.fire(events.global, events.event.error, { message = message, critical = false })
end

function error.critical(message)
  events.fire(events.global, events.event.error, { message = message, critical = true })
end

function error.show(data)
  vim.defer_fn(function()
    vim.api.nvim_err_write(data.message .. "\n")
  end, 10)
end

return error
