local mock = require("luassert.mock")

local display = require("microscope.api.display")

local vim_api

local function fake_ui(size)
  vim_api = mock(vim.api, true)
  vim_api.nvim_list_uis.returns({ size })
end

local function rect(width, height, col, row)
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

describe("display", function()
  after_each(function()
    mock.revert(vim_api)
  end)

  it("space is not stored in layout", function()
    local size = { width = 100, height = 100 }
    local ui_size = { width = 104, height = 104 }

    fake_ui(ui_size)

    assert.are.same(display.space():build(size).space, nil)
  end)

  it("layout is centered", function()
    local size = { width = 10, height = 10 }
    local ui_size = { width = 104, height = 104 }

    fake_ui(ui_size)

    local layout = display
      .vertical({
        display.horizontal({
          display.input(),
        }),
      })
      :build(size)

    assert.are.same(layout.input, rect(10, 10, 46, 46))
  end)

  describe("full size", function()
    local size = { width = 100, height = 100 }
    local ui_size = { width = 104, height = 104 }

    before_each(function()
      fake_ui(ui_size)
    end)

    describe("simple", function()
      it("uses fixed size", function()
        assert.are.same(display.input(2):build(size).input, rect(100, 2, 1, 1))
        assert.are.same(display.results(2):build(size).results, rect(100, 2, 1, 1))
        assert.are.same(display.preview(2):build(size).preview, rect(100, 2, 1, 1))
      end)

      it("uses percentage size", function()
        assert.are.same(display.input("50%"):build(size).input, rect(100, 50, 1, 1))
        assert.are.same(display.results("50%"):build(size).results, rect(100, 50, 1, 1))
        assert.are.same(display.preview("50%"):build(size).preview, rect(100, 50, 1, 1))
      end)

      it("grows to fill the provided size", function()
        assert.are.same(display.input():build(size).input, rect(100, 100, 1, 1))
        assert.are.same(display.results():build(size).results, rect(100, 100, 1, 1))
        assert.are.same(display.preview():build(size).preview, rect(100, 100, 1, 1))
      end)
    end)

    describe("complex", function()
      it("vertical", function()
        local layout = display
          .vertical({
            display.input(1),
            display.results("50%"),
            display.space(2),
            display.preview(),
          }, 20)
          :build(size)

        assert.are.same(layout, {
          input = rect(100, 1, 1, 1),
          results = rect(100, 10, 1, 4),
          preview = rect(100, 3, 1, 18),
        })
      end)

      it("horizontal", function()
        local layout = display
          .horizontal({
            display.input(1),
            display.results("50%"),
            display.space(2),
            display.preview(),
          }, 20)
          :build(size)

        assert.are.same(layout, {
          input = rect(1, 20, 1, 1),
          results = rect(50, 20, 4, 1),
          preview = rect(43, 20, 58, 1),
        })
      end)

      it("mixed", function()
        local layout = display
          .vertical({
            display.input(1),
            display.horizontal({
              display.results(),
              display.preview(),
            }, 10),
          }, 10)
          :build(size)

        assert.are.same(layout, {
          input = rect(100, 1, 1, 1),
          results = rect(49, 10, 1, 4),
          preview = rect(49, 10, 52, 4),
        })
      end)
    end)
  end)
end)
