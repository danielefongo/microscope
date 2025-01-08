local helpers = require("tests.helpers")
local display = require("microscope.api.display")

describe("display", function()
  local ui_size = { width = 104, height = 104 }

  helpers.setup({ ui_size = ui_size })

  it("space is not stored in layout", function()
    local size = { width = 100, height = 100 }

    assert.are.same(display.space():build(size).space, nil)
  end)

  it("layout is centered", function()
    local size = { width = 10, height = 10 }

    local layout = display
      .vertical({
        display.horizontal({
          display.input(),
        }),
      })
      :build(size)

    assert.are.same(layout.input, helpers.layout(10, 10, 46, 46))
  end)

  describe("full size", function()
    local size = { width = 100, height = 100 }

    describe("simple", function()
      it("uses fixed size", function()
        assert.are.same(display.input(2):build(size).input, helpers.layout(100, 2, 1, 1))
        assert.are.same(display.results(2):build(size).results, helpers.layout(100, 2, 1, 1))
        assert.are.same(display.preview(2):build(size).preview, helpers.layout(100, 2, 1, 1))
      end)

      it("uses percentage size", function()
        assert.are.same(display.input("50%"):build(size).input, helpers.layout(100, 49, 1, 1))
        assert.are.same(display.results("50%"):build(size).results, helpers.layout(100, 49, 1, 1))
        assert.are.same(display.preview("50%"):build(size).preview, helpers.layout(100, 49, 1, 1))
      end)

      it("grows to fill the provided size", function()
        assert.are.same(display.input():build(size).input, helpers.layout(100, 100, 1, 1))
        assert.are.same(display.results():build(size).results, helpers.layout(100, 100, 1, 1))
        assert.are.same(display.preview():build(size).preview, helpers.layout(100, 100, 1, 1))
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
          input = helpers.layout(100, 1, 1, 1),
          results = helpers.layout(100, 9, 1, 4),
          preview = helpers.layout(100, 4, 1, 17),
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
          input = helpers.layout(1, 20, 1, 1),
          results = helpers.layout(49, 20, 4, 1),
          preview = helpers.layout(44, 20, 57, 1),
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
          input = helpers.layout(100, 1, 1, 1),
          results = helpers.layout(49, 10, 1, 4),
          preview = helpers.layout(49, 10, 52, 4),
        })
      end)
    end)
  end)

  it("as layout", function()
    local opts = { ui_size = ui_size, finder_size = { width = 10, height = 10 } }

    local layout_spec = display.vertical({
      display.horizontal({
        display.input(),
      }),
    })

    assert.are.same(layout_spec:ui_layout()(opts).input, helpers.layout(100, 100, 1, 1))
    assert.are.same(layout_spec:finder_layout()(opts).input, helpers.layout(10, 10, 46, 46))
  end)
end)
