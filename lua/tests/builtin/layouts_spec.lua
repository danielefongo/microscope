local mock = require("luassert.mock")

local helpers = require("tests.helpers")
local layouts = require("microscope.builtin.layouts")

local vim_api
local function fake_ui(size)
  vim_api = mock(vim.api, true)
  vim_api.nvim_list_uis.returns({ size })
  return size
end

describe("layouts", function()
  helpers.eventually_store_coverage()

  after_each(function()
    mock.revert(vim_api)
  end)

  describe("default", function()
    it("build without preview", function()
      local ui_size = fake_ui({ width = 104, height = 104 })
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
      local ui_size = fake_ui({ width = 104, height = 104 })
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
      local ui_size = fake_ui({ width = 104, height = 104 })
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
