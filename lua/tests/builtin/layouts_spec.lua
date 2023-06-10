local helpers = require("tests.helpers")
local layouts = require("microscope.builtin.layouts")

describe("layouts", function()
  local ui_size = { width = 104, height = 104 }
  helpers.setup({ ui_size = ui_size })

  describe("default", function()
    it("build without preview", function()
      local finder_size = { width = 100, height = 100 }

      assert.are.same(
        layouts.default({
          ui_size = ui_size,
          finder_size = finder_size,
          full_screen = false,
          preview = false,
        }),
        {
          input = helpers.layout(58, 1, 22, 1),
          results = helpers.layout(58, 97, 22, 4),
        }
      )
    end)

    it("build with preview when ui_size is bigger than finder_size", function()
      local finder_size = { width = 100, height = 100 }

      assert.are.same(
        layouts.default({
          ui_size = ui_size,
          finder_size = finder_size,
          full_screen = false,
          preview = true,
        }),
        {
          input = helpers.layout(49, 1, 1, 1),
          results = helpers.layout(49, 97, 1, 4),
          preview = helpers.layout(49, 100, 52, 1),
        }
      )
    end)

    it("build with preview when ui_size less bigger than finder_size", function()
      local finder_size = { width = 200, height = 200 }

      assert.are.same(
        layouts.default({
          ui_size = ui_size,
          finder_size = finder_size,
          full_screen = false,
          preview = true,
        }),
        {
          input = helpers.layout(100, 1, 1, 1),
          results = helpers.layout(100, 47, 1, 4),
          preview = helpers.layout(100, 47, 1, 53),
        }
      )
    end)
  end)
end)
