local input = require("microscope.ui.input")
local events = require("microscope.events")
local helpers = require("tests.helpers")

describe("input", function()
  local input_window

  before_each(function()
    input_window = input.new()
    input_window:show(helpers.dummy_layout(), true)
  end)

  after_each(function()
    input_window:close()
  end)

  describe("event", function()
    describe("new_opts", function()
      it("stores new prompt", function()
        assert.are.same(input_window.prompt, "% ")

        events.fire(events.event.new_opts, {
          prompt = "newprompt >",
        })
        helpers.wait(10)

        assert.are.same(input_window.prompt, "newprompt >")
      end)
    end)
  end)

  describe("search", function()
    it("text", function()
      local input_changed = helpers.spy_event_handler(events.event.input_changed)

      vim.api.nvim_set_current_buf(input_window:get_buf())
      helpers.wait(10)

      helpers.insert("text")
      helpers.wait(20)

      helpers.remove_spy_event_handler(input_changed)

      assert.spy(input_changed).was.called_with("text")
    end)

    it("empty text on reset", function()
      local input_changed = helpers.spy_event_handler(events.event.input_changed)

      vim.api.nvim_set_current_buf(input_window:get_buf())
      helpers.wait(10)

      input_window:reset()
      helpers.wait(50)

      helpers.remove_spy_event_handler(input_changed)

      assert.spy(input_changed).was.called_with("")
    end)

    it("with set_text", function()
      local input_changed = helpers.spy_event_handler(events.event.input_changed)

      vim.api.nvim_set_current_buf(input_window:get_buf())
      helpers.wait(10)

      input_window:set_text("text")
      helpers.wait(50)

      helpers.remove_spy_event_handler(input_changed)

      assert.spy(input_changed).was.called_with("text")
    end)
  end)
end)
