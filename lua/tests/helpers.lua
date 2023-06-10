local stub = require("luassert.stub")
local spy = require("luassert.spy")
local events = require("microscope.events")

-- local functions

local function setup_defer_fn(defer_fn)
  local time = defer_fn or 0

  before_each(function()
    stub(vim, "defer_fn", function(fn)
      vim.wait(time)
      fn()
    end)
  end)

  after_each(function()
    if vim.defer_fn then
      vim.defer_fn:revert()
    end
  end)
end

local function setup_ui(ui_size)
  local size = ui_size or { width = 100, height = 100 }

  before_each(function()
    stub(vim.api, "nvim_list_uis", function()
      return { size }
    end)
  end)

  after_each(function()
    if vim.api.nvim_list_uis then
      vim.api.nvim_list_uis:revert()
    end
  end)
end

local function setup_write()
  before_each(function()
    stub(vim.api, "nvim_out_write")
  end)

  after_each(function()
    if vim.api.nvim_out_write then
      vim.api.nvim_out_write:revert()
    end
  end)
end

local function setup_test_cov()
  after_each(function()
    if os.getenv("TEST_COV") then
      require("luacov.runner").save_stats()
    end
  end)
end

-- helpers

local helpers = {}

function helpers.feed(text, feed_opts)
  feed_opts = feed_opts or "n"
  local to_feed = vim.api.nvim_replace_termcodes(text, true, false, true)
  vim.api.nvim_feedkeys(to_feed, feed_opts, true)
end

function helpers.insert(text)
  helpers.feed("i" .. text, "x")
end

function helpers.focus(microscope_window)
  vim.api.nvim_set_current_win(microscope_window:get_win())
  vim.api.nvim_set_current_buf(microscope_window:get_buf())
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

  helpers.wait(time or 10)

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

function helpers.setup(opts)
  opts = opts or {}

  setup_defer_fn(opts.defer_fn)
  setup_ui(opts.ui_size)
  setup_write()
  setup_test_cov()
end

return helpers
