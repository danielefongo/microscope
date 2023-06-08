local helpers = require("tests.helpers")
local lens = require("microscope.api.lens")
local lenses = require("microscope.builtin.lenses")

describe("lens", function()
  helpers.eventually_store_coverage()

  describe("fzf", function()
    it("with empty request", function()
      local my_lens = lens.new(lenses.fzf({
        fun = function(flow)
          flow.write({ "hello", "world" })
        end,
      }))

      my_lens:feed({ text = "" })

      assert.are.same(helpers.consume_lens(my_lens), "hello\nworld\n")
    end)

    it("with non-empty request", function()
      local my_lens = lens.new(lenses.fzf({
        fun = function(flow)
          flow.write({ "hello", "world" })
        end,
      }))

      my_lens:feed({ text = "wo" })

      assert.are.same(helpers.consume_lens(my_lens), "world\n")
    end)
  end)

  describe("head", function()
    it("when results are more than the provided size", function()
      local my_lens = lens.new(lenses.head(1, {
        fun = function(flow)
          flow.write({ "hello", "world" })
        end,
      }))

      my_lens:feed({ text = "" })

      assert.are.same(helpers.consume_lens(my_lens), "hello\n")
    end)

    it("when results are less than the provided size", function()
      local my_lens = lens.new(lenses.head(3, {
        fun = function(flow)
          flow.write({ "hello", "world" })
        end,
      }))

      my_lens:feed({ text = "" })

      assert.are.same(helpers.consume_lens(my_lens), "hello\nworld\n")
    end)
  end)

  describe("cache", function()
    it("returns data on first call", function()
      local my_lens = lens.new(lenses.cache({
        fun = function(flow, request)
          flow.write({ request.text })
        end,
      }))

      my_lens:feed({ text = "text" })

      assert.are.same(helpers.consume_lens(my_lens), "text\n")
    end)

    it("returns cached data on consecutive calls", function()
      local my_lens = lens.new(lenses.cache({
        fun = function(flow, request)
          flow.write({ request.text })
        end,
      }))

      my_lens:feed({ text = "text" })
      helpers.consume_lens(my_lens)

      my_lens:feed({ text = "text 2" })

      assert.are.same(helpers.consume_lens(my_lens), "text\n")
    end)
  end)
end)
