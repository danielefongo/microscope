local spy = require("luassert.spy")
local events = require("microscope.events")

local helpers = {}

function helpers.feed(text, feed_opts)
  feed_opts = feed_opts or "n"
  local to_feed = vim.api.nvim_replace_termcodes(text, true, false, true)
  vim.api.nvim_feedkeys(to_feed, feed_opts, true)
end

function helpers.insert(text)
  helpers.feed("i" .. text, "x")
end

function helpers.wait(duration)
  vim.wait(duration, function() end)
end

function helpers.dummy_layout()
  return {
    relative = "editor",
    width = 1,
    height = 1,
    col = 1,
    row = 1,
    style = "minimal",
    border = "rounded",
  }
end

function helpers.spy_event_handler(evt)
  local my_spy = spy.new(function() end)
  events.on(my_spy, evt, function(_, ...)
    my_spy(...)
  end)
  return my_spy
end

return helpers
