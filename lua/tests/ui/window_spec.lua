local window = require("microscope.ui.window")
local events = require("microscope.events")
local helpers = require("tests.helpers")

describe("window", function()
  local custom_window

  before_each(function()
    custom_window = window.new({}, events.new())
  end)

  after_each(function()
    custom_window:close()
  end)

  helpers.setup()

  describe("opt", function()
    it("does not set win opt if there is no window", function()
      custom_window:set_win_opt("wrap", true)

      assert.are.same(custom_window:get_win_opt("wrap"), nil)
    end)

    it("sets win opt if there is a window", function()
      custom_window:show(helpers.dummy_layout())

      custom_window:set_win_opt("wrap", true)
      assert.are.same(vim.api.nvim_win_get_option(custom_window:get_win(), "wrap"), true)

      custom_window:set_win_opt("wrap", false)
      assert.are.same(vim.api.nvim_win_get_option(custom_window:get_win(), "wrap"), false)
    end)

    it("sets buf opt", function()
      vim.api.nvim_buf_set_option(custom_window:get_buf(), "buftype", "nowrite")
      assert.are.same(custom_window:get_buf_opt("buftype"), "nowrite")

      vim.api.nvim_buf_set_option(custom_window:get_buf(), "buftype", "prompt")
      assert.are.same(custom_window:get_buf_opt("buftype"), "prompt")
    end)
  end)

  describe("write", function()
    it("from start to end", function()
      custom_window:write({ "hello", "world" })
      assert.are.same(vim.api.nvim_buf_get_lines(custom_window:get_buf(), 0, -1, true), {
        "hello",
        "world",
      })
    end)

    it("with range", function()
      vim.api.nvim_buf_set_lines(custom_window:get_buf(), 0, -1, true, {
        "hello",
        "world",
        "!",
      })

      custom_window:write({ "dan" }, 1, 2)
      assert.are.same(vim.api.nvim_buf_get_lines(custom_window:get_buf(), 0, -1, true), {
        "hello",
        "dan",
        "!",
      })

      custom_window:write({ "dan" }, 2)
      assert.are.same(vim.api.nvim_buf_get_lines(custom_window:get_buf(), 0, -1, true), {
        "hello",
        "dan",
        "dan",
      })
    end)

    it("do nothing if already closed", function()
      custom_window:close()
      custom_window:write({ "any" })

      assert.are.same(custom_window:read(), nil)
    end)
  end)

  it("clear", function()
    custom_window:show(helpers.dummy_layout())

    vim.api.nvim_buf_set_lines(custom_window:get_buf(), 0, -1, true, {
      "hello",
      "world",
      "!",
    })
    vim.api.nvim_win_set_cursor(custom_window:get_win(), { 3, 0 })

    custom_window:clear()
    assert.are.same(vim.api.nvim_buf_get_lines(custom_window:get_buf(), 0, -1, true), { "" })
    assert.are.same(vim.api.nvim_win_get_cursor(custom_window:get_win()), { 1, 0 })
  end)

  it("count", function()
    vim.api.nvim_buf_set_lines(custom_window:get_buf(), 0, -1, true, {
      "hello",
      "world",
      "!",
    })

    assert.are.same(custom_window:line_count(), 3)
  end)

  describe("read", function()
    it("empty", function()
      assert.are.same(custom_window:read(), { "" })
    end)

    it("full", function()
      vim.api.nvim_buf_set_lines(custom_window:get_buf(), 0, -1, true, {
        "hello",
        "world",
        "!",
      })

      assert.are.same(custom_window:read(), { "hello", "world", "!" })
    end)

    it("with range", function()
      vim.api.nvim_buf_set_lines(custom_window:get_buf(), 0, -1, true, {
        "hello",
        "world",
        "!",
      })

      assert.are.same(custom_window:read(1), { "world", "!" })
      assert.are.same(custom_window:read(1, 2), { "world" })
      assert.are.same(custom_window:read(2, 3), { "!" })
    end)
  end)

  describe("set_cursor", function()
    it("inside allowed range", function()
      custom_window:show(helpers.dummy_layout())

      vim.api.nvim_buf_set_lines(custom_window:get_buf(), 0, -1, true, {
        "hello",
        "world",
        "!",
      })

      custom_window:set_cursor({ 1, 0 })
      assert.are.same(vim.api.nvim_win_get_cursor(custom_window:get_win()), { 1, 0 })

      custom_window:set_cursor({ 3, 0 })
      assert.are.same(vim.api.nvim_win_get_cursor(custom_window:get_win()), { 3, 0 })
    end)

    it("in boundaries if outside allowed row range", function()
      custom_window:show(helpers.dummy_layout())

      vim.api.nvim_buf_set_lines(custom_window:get_buf(), 0, -1, true, {
        "hello",
        "world",
        "!",
      })

      custom_window:set_cursor({ 1, 0 })

      custom_window:set_cursor({ 0, 0 })
      assert.are.same(vim.api.nvim_win_get_cursor(custom_window:get_win()), { 1, 0 })

      custom_window:set_cursor({ 4, 0 })
      assert.are.same(vim.api.nvim_win_get_cursor(custom_window:get_win()), { 3, 0 })
    end)

    it("in boundaries if outside allowed col range", function()
      custom_window:show(helpers.dummy_layout())

      vim.api.nvim_buf_set_lines(custom_window:get_buf(), 0, -1, true, {
        "he",
      })

      custom_window:set_cursor({ 1, 0 })

      custom_window:set_cursor({ 1, -1 })
      assert.are.same(vim.api.nvim_win_get_cursor(custom_window:get_win()), { 1, 0 })

      custom_window:set_cursor({ 1, 2 })
      assert.are.same(vim.api.nvim_win_get_cursor(custom_window:get_win()), { 1, 1 })
    end)

    it("in boundaries if no text", function()
      custom_window:show(helpers.dummy_layout())

      custom_window:set_cursor({ 1, 0 })
      assert.are.same(vim.api.nvim_win_get_cursor(custom_window:get_win()), { 1, 0 })
    end)
  end)

  describe("get_cursor", function()
    it("if window is shown", function()
      custom_window:show(helpers.dummy_layout())

      custom_window:set_cursor({ 1, 0 })
      assert.are.same(custom_window:get_cursor(), { 1, 0 })
    end)

    it("if window is not shown", function()
      custom_window:set_cursor({ 1, 0 })
      assert.are.same(custom_window:get_cursor(), { 1, 0 })
    end)
  end)

  it("set_title", function()
    custom_window:show(helpers.dummy_layout())

    custom_window:set_title("search", "center")
    assert.are.same(vim.api.nvim_win_get_config(custom_window:get_win()).title, {
      { "search", "FloatTitle" },
    })
  end)

  it("get_title", function()
    custom_window:show(helpers.dummy_layout())

    custom_window:set_title("search", "center")
    assert.are.same(custom_window:get_title(), {
      title = "search",
      title_pos = "center",
    })
  end)

  describe("show", function()
    it("displays new window with layout", function()
      assert.are.same(custom_window:get_win(), nil)

      local layout = helpers.dummy_layout()

      custom_window:show(layout)

      local config = vim.api.nvim_win_get_config(custom_window:get_win())

      assert.is_not.Nil(custom_window:get_win())
      assert.are.same(config.height, layout.height)
      assert.are.same(config.width, layout.width)
      assert.are.same(config.relative, layout.relative)
    end)

    it("overrides layout", function()
      assert.are.same(custom_window:get_win(), nil)

      local layout = helpers.dummy_layout()
      layout.height = 10

      custom_window:show(layout)

      layout.height = 20

      custom_window:show(layout)

      local config = vim.api.nvim_win_get_config(custom_window:get_win())

      assert.is_not.Nil(custom_window:get_win())
      assert.are.same(config.height, 20)
    end)

    it("hides window if layout is nil", function()
      assert.is.Nil(custom_window:get_win())

      custom_window:show(helpers.dummy_layout())
      custom_window:show()

      assert.is.Nil(custom_window:get_win())
    end)

    it("sets previously changed cursor if focus is on", function()
      custom_window:write({ "hello", "world" })
      custom_window:set_cursor({ 2, 0 })

      custom_window:show(helpers.dummy_layout(), true)

      assert.are.same(vim.api.nvim_win_get_cursor(custom_window:get_win()), { 2, 0 })
    end)

    it("focuses window if focus is on", function()
      local win = vim.api.nvim_get_current_win()

      custom_window:show(helpers.dummy_layout(), false)

      vim.api.nvim_set_current_win(win)

      custom_window:show(helpers.dummy_layout(), true)

      assert.are.same(vim.api.nvim_get_current_win(), custom_window:get_win())
    end)

    it("restores hidden window", function()
      local layout = helpers.dummy_layout()
      assert.is.Nil(custom_window:get_win())

      custom_window:show(layout)
      custom_window:show()
      custom_window:show(layout)

      local config = vim.api.nvim_win_get_config(custom_window:get_win())

      assert.is_not.Nil(custom_window:get_win())
      assert.are.same(config.height, layout.height)
      assert.are.same(config.width, layout.width)
      assert.are.same(config.relative, layout.relative)
    end)
  end)

  describe("close", function()
    it("destroys everything", function()
      custom_window:show(helpers.dummy_layout())
      custom_window:close()

      assert.is.Nil(custom_window:get_buf())
      assert.is.Nil(custom_window:get_win())
      assert.is.Nil(custom_window:get_cursor())
    end)

    it("safely close if the window was closed from vim", function()
      custom_window:show(helpers.dummy_layout())

      vim.api.nvim_win_close(custom_window:get_win(), true)

      custom_window:close()

      assert.is.Nil(custom_window:get_buf())
      assert.is.Nil(custom_window:get_win())
      assert.is.Nil(custom_window:get_cursor())
    end)
  end)

  describe("highlights", function()
    it("sets/clears buffer highlights correctly", function()
      custom_window:show(helpers.dummy_layout())

      vim.api.nvim_buf_set_lines(custom_window:get_buf(), 0, -1, true, {
        "hello world",
        "test highlights",
      })

      local highlights = {
        [1] = { { from = 1, to = 5, color = "String" } },
        [2] = { { from = 1, to = 4, color = "Keyword" }, { from = 6, to = 15, color = "Comment" } },
      }

      custom_window:set_buf_hls(highlights)

      assert.are.same(helpers.get_highlight_details(custom_window, 1), {
        line = 1,
        from = 1,
        to = 5,
        color = "String",
      })
      assert.are.same(helpers.get_highlight_details(custom_window, 2), {
        line = 2,
        from = 1,
        to = 4,
        color = "Keyword",
      })
      assert.are.same(helpers.get_highlight_details(custom_window, 3), {
        line = 2,
        from = 6,
        to = 15,
        color = "Comment",
      })
    end)
  end)
end)
