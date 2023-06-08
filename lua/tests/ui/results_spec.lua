local window = require("microscope.ui.window")
local highlight = require("microscope.api.highlight")
local results = require("microscope.ui.results")
local events = require("microscope.events")
local helpers = require("tests.helpers")

local function get_highlight_details(buf, highlight_number)
  local extmark = vim.api.nvim_buf_get_extmark_by_id(buf, window.namespace, highlight_number, { details = true })
  return {
    line = extmark[1] + 1,
    from = extmark[2] + 1,
    to = extmark[3].end_col,
    color = extmark[3].hl_group,
  }
end

describe("results", function()
  local results_window

  before_each(function()
    results_window = results.new()
  end)

  after_each(function()
    results_window:close()
  end)

  helpers.eventually_store_coverage()

  describe("event", function()
    describe("results_retrieved", function()
      it("writes to buffer", function()
        events.fire(events.event.results_retrieved, { "result1", "result2" })
        helpers.wait(10)

        assert.are.same(results_window:read(), { "result1", "result2" })
      end)

      it("overwrites buffer on new results", function()
        events.fire(events.event.results_retrieved, { "result1", "result2" })
        helpers.wait(10)

        events.fire(events.event.results_retrieved, { "result3" })
        helpers.wait(10)

        assert.are.same(results_window:read(), { "result3" })
      end)

      it("triggers result focused on first result", function()
        local focus = helpers.spy_event_handler(events.event.result_focused)

        events.fire(events.event.results_retrieved, { "result1", "result2" })
        helpers.wait(300)

        assert.spy(focus).was.called_with({ text = "result1" })
      end)
    end)

    describe("empty_results_retrieved", function()
      it("resets buffer", function()
        events.fire(events.event.results_retrieved, { "result1", "result2" })
        helpers.wait(10)

        events.fire(events.event.empty_results_retrieved)
        helpers.wait(10)

        assert.are.same(results_window:read(), { "" })
      end)
    end)

    describe("new_request", function()
      it("resets everything, except the buffer", function()
        events.fire(events.event.results_retrieved, { "result1", "result2" })
        helpers.wait(10)

        events.fire(events.event.new_request, { text = "smth" })
        helpers.wait(10)

        assert.are.same(results_window:read(), { "result1", "result2" })
        assert.are.same(results_window:raw_results(), {})
        assert.are.same(results_window:selected(), {})
      end)
    end)

    describe("new_opts", function()
      it("stores new parser", function()
        events.fire(events.event.new_opts, {
          parsers = {
            function(data)
              data.additional_data = true
              return data
            end,
          },
        })
        helpers.wait(10)

        events.fire(events.event.results_retrieved, { "result1", "result2" })
        helpers.wait(10)

        assert.are.same(results_window:selected(), { { text = "result1", additional_data = true } })
      end)
    end)

    describe("cursor_moved", function()
      it("sets new cursor if different from previous one", function()
        events.fire(events.event.results_retrieved, { "result1", "result2" })
        helpers.wait(10)

        results_window:show(helpers.dummy_layout(), false)
        vim.api.nvim_win_set_cursor(results_window.win, { 2, 0 })
        events.fire_native(events.event.cursor_moved)
        helpers.wait(20)

        assert.are.same(results_window:get_cursor(), { 2, 0 })
      end)
    end)
  end)

  describe("parsing", function()
    it("shows modified text", function()
      events.fire(events.event.new_opts, {
        parsers = {
          function(data)
            data.text = data.text .. " changed"
            return data
          end,
        },
      })
      helpers.wait(10)

      events.fire(events.event.results_retrieved, { "result1", "result2" })
      helpers.wait(10)

      assert.are.same(results_window:read(), {
        "result1 changed",
        "result2 changed",
      })
    end)

    it("shows highlights", function()
      events.fire(events.event.new_opts, {
        parsers = {
          function(data)
            data.highlights = highlight.new({}, data.text):hl(highlight.color.color1, 1, 1):get_highlights()
            return data
          end,
        },
      })
      helpers.wait(10)

      events.fire(events.event.results_retrieved, { "result1", "result2" })
      helpers.wait(10)

      assert.are.same(get_highlight_details(results_window.buf, 1), {
        line = 1,
        from = 1,
        to = 1,
        color = highlight.color.color1,
      })

      assert.are.same(get_highlight_details(results_window.buf, 2), {
        line = 2,
        from = 1,
        to = 1,
        color = highlight.color.color1,
      })
    end)
  end)

  describe("moving cursor", function()
    it("triggers result_focused event if there is a result", function()
      local focus = helpers.spy_event_handler(events.event.result_focused)

      events.fire(events.event.results_retrieved, { "result1", "result2" })
      helpers.wait(10)

      results_window:set_cursor({ 2, 0 })
      helpers.wait(300)

      helpers.remove_spy_event_handler(focus)

      assert.spy(focus).was.called_with({ text = "result2" })
    end)

    it("does not trigger result_focused event if there isn't any result", function()
      local focus = helpers.spy_event_handler(events.event.result_focused)

      events.fire(events.event.results_retrieved, {})
      helpers.wait(10)

      results_window:set_cursor({ 2, 0 })
      helpers.wait(300)

      helpers.remove_spy_event_handler(focus)

      assert.spy(focus).was.not_called()
    end)

    it("parses results", function()
      local retrieved_results = {}
      for i = 1, 200, 1 do
        table.insert(retrieved_results, "result" .. tostring(i))
      end

      events.fire(events.event.results_retrieved, retrieved_results)
      helpers.wait(10)

      results_window:set_cursor({ 200, 0 })
      helpers.wait(10)

      assert.are.same(results_window:selected(), { { text = "result200" } })
    end)
  end)

  describe("selection", function()
    it("highlights result on buffer", function()
      events.fire(events.event.results_retrieved, { "result1", "result2" })
      helpers.wait(10)

      results_window:select()

      assert.are.same(results_window:read(), { "> result1", "result2" })

      results_window:select()

      assert.are.same(results_window:read(), { "result1", "result2" })
    end)

    it("contains selected results", function()
      events.fire(events.event.results_retrieved, { "result1", "result2" })
      helpers.wait(10)

      results_window:select()

      assert.are.same(results_window:selected(), { { text = "result1" } })
    end)

    it("is empty on no results", function()
      events.fire(events.event.empty_results_retrieved)

      results_window:select()

      assert.are.same(results_window:selected(), {})
    end)
  end)

  describe("opening", function()
    it("focused result", function()
      local open = helpers.spy_event_handler(events.event.results_opened)

      events.fire(events.event.results_retrieved, { "result1", "result2" })
      helpers.wait(10)

      results_window:open("metadata")
      helpers.wait(10)

      helpers.remove_spy_event_handler(open)

      assert.spy(open).was.called_with({
        selected = { { text = "result1" } },
        metadata = "metadata",
      })
    end)

    it("selected results", function()
      local open = helpers.spy_event_handler(events.event.results_opened)

      events.fire(events.event.results_retrieved, { "result1", "result2", "result3" })
      helpers.wait(10)

      results_window:select()
      results_window:set_cursor({ 2, 0 })
      results_window:set_cursor({ 3, 0 })
      results_window:select()
      results_window:open("metadata")
      helpers.wait(10)

      helpers.remove_spy_event_handler(open)

      assert.spy(open).was.called_with({
        selected = { { text = "result1" }, { text = "result3" } },
        metadata = "metadata",
      })
    end)

    it("nothing if no results", function()
      local open = helpers.spy_event_handler(events.event.results_opened)

      results_window:open("metadata")
      helpers.wait(10)

      helpers.remove_spy_event_handler(open)

      assert.spy(open).was.not_called()
    end)
  end)
end)
