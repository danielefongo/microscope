local preview = require("microscope.ui.preview")
local events = require("microscope.events")
local helpers = require("tests.helpers")

describe("preview", function()
  local preview_window

  before_each(function()
    preview_window = preview.new()
    preview_window:show(helpers.dummy_layout(), true)
  end)

  after_each(function()
    preview_window:close()
  end)

  helpers.eventually_store_coverage()

  describe("event", function()
    describe("result_focused", function()
      it("calls the preview function", function()
        local preview_fn = helpers.spy_function()

        events.fire(events.event.new_opts, {
          preview = function(data, _)
            preview_fn(data)
          end,
        })
        events.fire(events.event.result_focused, { text = "smth" })
        helpers.wait(10)

        assert.spy(preview_fn).was.called_with({ text = "smth" })
      end)
    end)

    describe("empty_results_retrieved", function()
      it("clears the buffer", function()
        preview_window:write({ "some", "text" })

        assert.are.same(preview_window:read(), { "some", "text" })

        events.fire(events.event.empty_results_retrieved)
        helpers.wait(10)

        assert.are.same(preview_window:read(), { "" })
      end)
    end)

    describe("new_opts", function()
      it("refresh window if the function is changed", function()
        local preview_fn = helpers.spy_function()

        events.fire(events.event.result_focused, { text = "smth" })
        helpers.wait(10)

        events.fire(events.event.new_opts, {
          preview = function(data, _)
            preview_fn(data)
          end,
        })
        helpers.wait(10)

        assert.spy(preview_fn).was.called_with({ text = "smth" })
      end)

      it("does not refresh window if the function is not changed", function()
        local preview_fn = helpers.spy_function()
        local fun = function(data, _)
          preview_fn(data)
        end

        events.fire(events.event.result_focused, { text = "smth" })
        helpers.wait(10)

        events.fire(events.event.new_opts, { preview = fun })
        helpers.wait(10)

        events.fire(events.event.new_opts, { preview = fun })
        helpers.wait(10)

        assert.spy(preview_fn).was.called(1)
      end)
    end)
  end)

  describe("write_term", function()
    it("writes lines", function()
      preview_window:write_term({
        "\27[1mhello\27[m",
        "\27[1mworld\27[m",
      })

      helpers.wait(10)

      assert.are.same(preview_window:read(), {
        "hello",
        "world",
      })
    end)

    it("trims length", function()
      local expected = ""
      for _ = 1, preview_window.layout.width, 1 do
        expected = expected .. "x"
      end
      local full = expected .. "xxxxxxxxxxx"

      preview_window:write_term({
        "\27[1m" .. full .. "\27[m",
      })

      helpers.wait(10)

      assert.are.same(preview_window:read(), {
        expected,
      })
    end)
  end)
end)
