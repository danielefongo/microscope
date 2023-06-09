local helpers = require("tests.helpers")
local user = require("tests.user")

local lenses = require("microscope.builtin.lenses")

describe("microscope", function()
  helpers.eventually_store_coverage()

  local microscope

  before_each(function()
    microscope = require("microscope")
  end)

  after_each(function()
    package.loaded[microscope] = nil
    _G[microscope] = nil
  end)

  it("basic setup", function()
    microscope.setup({ size = { height = 10, width = 10 } })

    assert.are.same(microscope.opts, {
      prompt = "> ",
      size = { height = 10, width = 10 },
      bindings = {},
    })
  end)

  it("basic setup with prompt override", function()
    microscope.setup({ size = { height = 10, width = 10 }, prompt = "~> " })

    assert.are.same(microscope.opts, {
      prompt = "~> ",
      size = { height = 10, width = 10 },
      bindings = {},
    })
  end)

  it("create finder", function()
    local my_lens = lenses.write({})

    microscope.setup({ size = { height = 10, width = 10 } })

    local finder = microscope.finder({
      lens = my_lens,
      parsers = {},
    })

    assert.are.same(finder.opts, {
      prompt = "> ",
      size = { height = 10, width = 10 },
      bindings = {},
      lens = my_lens,
      parsers = {},
    })
  end)

  it("override finder opts", function()
    local my_lens = lenses.write({})
    local my_parser = function()
      return { text = "smth" }
    end

    microscope.setup({ size = { height = 10, width = 10 } })

    local finder = microscope
      .finder({
        lens = my_lens,
        parsers = {},
      })
      :override({
        parsers = { my_parser },
      })

    assert.are.same(finder.opts, {
      prompt = "> ",
      size = { height = 10, width = 10 },
      bindings = {},
      lens = my_lens,
      parsers = { my_parser },
    })
  end)

  it("open a finder", function()
    microscope.setup({ size = { height = 10, width = 10 } })

    local finder = microscope.finder({
      lens = lenses.write({}),
      parsers = {},
    })

    local my_user = user.set_finder(finder())

    my_user:sees_window("input")

    my_user:close_finder()
  end)

  it("open a registered finder", function()
    microscope.setup({ size = { height = 10, width = 10 } })

    microscope.register({
      my_finder = {
        lens = lenses.write({}),
        parsers = {},
      },
    })

    local my_user = user.set_finder(microscope.finders.my_finder())

    my_user:sees_window("input")

    my_user:close_finder()
  end)

  it("open an overrided finder", function()
    microscope.setup({ size = { height = 10, width = 10 } })

    microscope.register({
      my_finder = {
        lens = lenses.write({}),
        parsers = {},
      },
    })
    microscope.register({
      my_finder = {
        lens = lenses.write({}),
        preview = function() end,
        parsers = {},
      },
    })

    local my_user = user.set_finder(microscope.finders.my_finder())

    my_user:sees_window("input")
    my_user:sees_window("preview")

    my_user:close_finder()
  end)
end)
