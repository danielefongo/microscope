local input = require("microscope.ui.input")
local events = require("microscope.events")
local helpers = require("tests.helpers")

describe("input", function()
  local input_window
  local my_events

  before_each(function()
    my_events = events.new()
    input_window = input.new(my_events)
    input_window:show(helpers.dummy_layout(), true)
  end)

  after_each(function()
    input_window:close()
  end)

  helpers.setup()

  describe("event", function()
    describe("new_opts", function()
      it("stores new opts", function()
        local input_changed = helpers.spy_event_handler(my_events, input_window, events.event.input_changed)

        assert.are.same(input_window.prompt, input.default_prompt)

        my_events:fire(events.event.new_opts, {
          prompt = "newprompt >",
          args = { new = true },
        })
        helpers.wait(10)

        assert.are.same(input_window.prompt, "newprompt >")
        assert.spy(input_changed).was.called(1)
      end)

      it("emits input changed if args are different", function()
        local input_changed = helpers.spy_event_handler(my_events, input_window, events.event.input_changed)

        my_events:fire(events.event.new_opts, {
          prompt = input.default_prompt,
          args = { new = true },
        })
        my_events:fire(events.event.new_opts, {
          prompt = input.default_prompt,
          args = { new2 = true },
        })
        helpers.wait(10)

        assert.spy(input_changed).was.called(2)
      end)
    end)
  end)

  describe("text", function()
    it("get empty input", function()
      vim.api.nvim_set_current_buf(input_window:get_buf())
      helpers.wait(10)

      assert.are.same(input_window:text(), "")
    end)

    it("get non empty input", function()
      vim.api.nvim_set_current_buf(input_window:get_buf())
      helpers.wait(10)

      helpers.insert("text")
      helpers.wait(10)

      assert.are.same(input_window:text(), "text")
    end)

    it("do not change input on newline", function()
      vim.api.nvim_set_current_buf(input_window:get_buf())
      helpers.wait(20)

      helpers.insert("text")
      helpers.insert("<s-cr>")
      helpers.wait(20)

      assert.are.same(input_window:text(), "text")
    end)
  end)

  describe("search", function()
    it("does not trigger input_changed if input is the same", function()
      local input_changed = helpers.spy_event_handler(my_events, input_window, events.event.input_changed)

      vim.api.nvim_set_current_buf(input_window:get_buf())
      helpers.wait(20)

      helpers.insert("<bs>")
      helpers.wait(20)

      assert.spy(input_changed).was.called(1)
    end)

    it("text", function()
      local input_changed = helpers.spy_event_handler(my_events, input_window, events.event.input_changed)

      vim.api.nvim_set_current_buf(input_window:get_buf())
      helpers.wait(10)

      helpers.insert("text")
      helpers.wait(10)

      assert.spy(input_changed).was.called_with("text")
    end)

    it("empty text on reset", function()
      local input_changed = helpers.spy_event_handler(my_events, input_window, events.event.input_changed)

      vim.api.nvim_set_current_buf(input_window:get_buf())
      helpers.wait(10)

      input_window:reset()
      helpers.wait(10)

      assert.spy(input_changed).was.called_with("")
    end)

    it("with set_text", function()
      local input_changed = helpers.spy_event_handler(my_events, input_window, events.event.input_changed)

      vim.api.nvim_set_current_buf(input_window:get_buf())
      helpers.wait(10)

      input_window:set_text("text")
      helpers.wait(10)

      assert.spy(input_changed).was.called_with("text")
    end)
  end)
end)
