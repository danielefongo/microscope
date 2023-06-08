local spy = require("luassert.spy")
local events = require("microscope.events")

local helpers = {}

vim.api.nvim_list_uis = function()
  return {
    { width = 100, height = 100 },
  }
end
vim.defer_fn = function(fn)
  return fn()
end

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
    width = 10,
    height = 10,
    col = 1,
    row = 1,
    style = "minimal",
    border = "rounded",
  }
end

function helpers.spy_event_handler(evt)
  local my_spy = helpers.spy_function()
  events.on(my_spy, evt, function(_, ...)
    my_spy(...)
  end)
  return my_spy
end

function helpers.remove_spy_event_handler(my_spy)
  events.clear_module(my_spy)
end

function helpers.spy_function()
  return spy.new(function() end)
end

function helpers.consume_lens(my_lens, time)
  local final_out

  local async = vim.loop.new_idle()
  async:start(function()
    local out = my_lens:read()
    if out == nil then
      return async:stop()
    end
    final_out = (final_out or "") .. out
  end)

  helpers.wait(time or 30)

  return final_out
end

function helpers.layout(width, height, col, row)
  return {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  }
end

function helpers.eventually_store_coverage()
  after_each(function()
    if os.getenv("TEST_COV") then
      require("luacov.runner").save_stats()
    end
  end)
end

return helpers
