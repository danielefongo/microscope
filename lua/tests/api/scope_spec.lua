local helpers = require("tests.helpers")
local events = require("microscope.events")
local lenses = require("microscope.builtin.lenses")
local scope = require("microscope.api.scope")

local function slow(seconds, ...)
  return {
    fun = function(flow)
      local results = {}
      for input in flow.read_array_iter() do
        if input ~= "" then
          table.insert(results, input)
        end
      end

      flow.consume(flow.cmd.shell("sleep", { seconds }))

      for _, result in pairs(results) do
        flow.write(result)
      end
    end,
    inputs = { ... },
  }
end

describe("scope", function()
  helpers.setup()

  it("starts empty search", function()
    local my_data = nil

    scope
      .new({
        lens = lenses.write(""),
        callback = function(data)
          my_data = data
        end,
      })
      :search()

    vim.wait(10)

    assert.are.same(my_data, {})
  end)

  it("starts simple search", function()
    local my_data = {}

    scope
      .new({
        lens = lenses.write({ "hello", "world" }),
        callback = function(data)
          my_data = data
        end,
      })
      :search()

    vim.wait(10)

    assert.are.same(my_data, { "hello", "world" })
  end)

  it("starts simple search with string result", function()
    local my_data = {}

    scope
      .new({
        lens = lenses.write("hello\nworld\n"),
        callback = function(data)
          my_data = data
        end,
      })
      :search()

    vim.wait(10)

    assert.are.same(my_data, { "hello", "world" })
  end)

  it("stops simple search", function()
    local my_data = {}

    local my_scope = scope.new({
      lens = lenses.write({ "hello", "world" }),
      callback = function(data)
        my_data = data
      end,
    })

    my_scope:search()
    my_scope:stop()

    vim.wait(10)

    assert.are.same(my_data, {})
  end)

  it("starts slow search", function()
    local my_data = {}

    local my_scope = scope.new({
      lens = slow(0.1, lenses.write({ "hello", "world" })),
      callback = function(data)
        my_data = data
      end,
    })

    my_scope:search()

    vim.wait(150)

    assert.are.same(my_data, { "hello", "world" })
  end)

  it("stops slow search", function()
    local calls = 0

    local my_scope = scope.new({
      lens = slow(0.1, lenses.write({ "hello", "world" })),
      callback = function()
        calls = calls + 1
      end,
    })

    my_scope:search()

    vim.defer_fn(function()
      my_scope:stop()
    end, 10)

    vim.wait(150)

    assert.are.same(calls, 0)
  end)

  it("repeats slow search", function()
    local calls = 0

    local my_scope = scope.new({
      lens = slow(0.1, lenses.write({ "hello", "world" })),
      callback = function(data)
        calls = calls + 1
      end,
    })

    my_scope:search()

    vim.defer_fn(function()
      my_scope:search()
    end, 10)

    vim.wait(150)

    assert.are.same(calls, 1)
  end)

  it("fails if args are invalid", function()
    local spy = helpers.spy_event_handler(events.global, "any", events.event.error)

    scope
      .new({
        lens = {
          fun = function() end,
          args = {
            arg = true,
          },
        },
        callback = function() end,
      })
      :search("", {
        arg = "not valid type",
      })

    vim.wait(10)

    assert.spy(spy).was.called_with({
      critical = true,
      message = [[microscope: invalid arguments types
provided: {
  arg = "not valid type"
}
defaults: {
  arg = true
}]],
    })
  end)
end)
