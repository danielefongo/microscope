local preview = require("microscope.ui.preview")
local events = require("microscope.events")
local helpers = require("tests.helpers")

local function read_terminal_channel(terminal_buffer, terminal_channel)
  -- local terminal_buffer = vim.api.nvim_create_buf(false, true)
  -- local terminal_channel = vim.fn.termopen("<comando del terminale>")
  -- vim.api.nvim_set_current_buf(terminal_buffer)

  -- -- Collega il channel del terminale al buffer
  -- vim.fn.termattach(terminal_channel, terminal_buffer) -- Attendi un breve periodo di tempo per consentire al terminale di inviare dati al buffer
  vim.wait(100)

  local data = vim.api.nvim_call_function("getbufline", { terminal_buffer, 1, "$" })

  -- local data = vim.api.nvim_call_function("getbufline", { terminal_buffer, 1, "$" })
  vim.pretty_print(data)
end

describe("preview", function()
  local preview_window

  before_each(function()
    preview_window = preview.new()
    preview_window:show(helpers.dummy_layout(), true)
  end)

  after_each(function()
    preview_window:close()
  end)

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
