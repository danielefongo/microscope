local helpers = require("tests.helpers")
local user = require("tests.user")

local display = require("microscope.api.display")
local lenses = require("microscope.builtin.lenses")
local actions = require("microscope.builtin.actions")

describe("actions", function()
  local my_user

  helpers.eventually_store_coverage()

  after_each(function()
    my_user:close_finder()
  end)

  it("next + previous", function()
    my_user = user.open_finder({
      lens = lenses.write({ "hello", "world" }),
      bindings = {
        ["<c-j>"] = actions.next,
        ["<c-k>"] = actions.previous,
      },
    })

    my_user:focus("input")

    my_user:sees_text_in("results", { "hello", "world" })
    my_user:sees_focused_line_in("results", "hello")

    my_user:keystroke("<c-j>", "i")

    my_user:sees_focused_line_in("results", "world")

    my_user:keystroke("<c-j>", "i")

    my_user:sees_focused_line_in("results", "world")

    my_user:keystroke("<c-k>", "i")

    my_user:sees_focused_line_in("results", "hello")

    my_user:keystroke("<c-k>", "i")

    my_user:sees_focused_line_in("results", "hello")
  end)

  it("scroll_down + scroll_up", function()
    my_user = user.open_finder({
      lens = lenses.write({ "hello" }),
      preview = function(data, window)
        window:write({ data.text, "extra_line" })
        window:set_cursor({ 1, 0 })
      end,
      bindings = {
        ["<a-j>"] = actions.scroll_down,
        ["<a-k>"] = actions.scroll_up,
      },
    })

    my_user:focus("input")

    my_user:sees_text_in("preview", { "hello", "extra_line" })
    my_user:sees_focused_line_in("preview", "hello")

    my_user:keystroke("<a-j>", "i")

    my_user:sees_focused_line_in("preview", "extra_line")

    my_user:keystroke("<a-j>", "i")

    my_user:sees_focused_line_in("preview", "extra_line")

    my_user:keystroke("<a-k>", "i")

    my_user:sees_focused_line_in("preview", "hello")

    my_user:keystroke("<a-k>", "i")

    my_user:sees_focused_line_in("preview", "hello")
  end)

  it("open", function()
    local old_win = vim.api.nvim_get_current_win()

    my_user = user.open_finder({
      lens = lenses.write({ "hello", "world" }),
      open = function(data, request)
        vim.api.nvim_buf_set_lines(request.buf, 0, -1, true, { "opened", data.text })
      end,
      bindings = { ["<cr>"] = actions.open },
    })

    my_user:focus("input")
    my_user:keystroke("<cr>", "i")

    my_user:sees_text_in(old_win, { "opened", "hello" })
  end)

  it("selection", function()
    my_user = user.open_finder({
      lens = lenses.write({ "hello", "world" }),
      bindings = { ["<tab>"] = actions.select },
    })

    my_user:focus("input")

    my_user:sees_text_in("results", { "hello", "world" })

    my_user:keystroke("<tab>", "i")

    my_user:sees_text_in("results", { "> hello", "world" })

    my_user:keystroke("<tab>", "i")

    my_user:sees_text_in("results", { "> hello", "> world" })

    my_user:keystroke("<tab>", "i")

    my_user:sees_text_in("results", { "> hello", "world" })
  end)

  it("close", function()
    my_user = user.open_finder({
      lens = lenses.write({}),
      bindings = { ["<esc>"] = actions.close },
    })

    my_user:sees_window("input")
    my_user:sees_window("results")

    my_user:focus("input")
    my_user:keystroke("<esc>", "i")

    my_user:does_not_see_window("input")
    my_user:does_not_see_window("results")
  end)

  it("alter", function()
    my_user = user.open_finder({
      lens = lenses.write({}),
      bindings = {
        ["<a-x>"] = actions.alter({ prompt = "~~~> " }),
      },
    })

    my_user:focus("input")
    my_user:keystroke("<a-x>", "i")
    my_user:keystroke("smth", "i")

    my_user:sees_text_in("input", { "~~~> smth" })
  end)

  it("set_layout", function()
    local just_input_layout = function(opts)
      return display.input(1):build(opts.finder_size)
    end

    my_user = user.open_finder({
      lens = lenses.write({}),
      preview = function() end,
      bindings = {
        ["<a-p>"] = actions.set_layout(just_input_layout),
      },
    })

    my_user:sees_window("input")
    my_user:sees_window("results")
    my_user:sees_window("preview")

    my_user:focus("input")
    my_user:keystroke("<a-p>", "i")

    my_user:sees_window("input")
    my_user:does_not_see_window("results")
    my_user:does_not_see_window("preview")
  end)

  it("refine without any input", function()
    my_user = user.open_finder({
      lens = lenses.fzf(lenses.write({ "hello", "world" })),
      bindings = { ["<a-cr>"] = actions.refine },
    })

    my_user:focus("input")

    my_user:sees_text_in("results", { "hello", "world" })

    my_user:keystroke("<a-cr>", "i")

    my_user:sees_text_in("input", { "> " })
  end)

  it("refine", function()
    my_user = user.open_finder({
      lens = lenses.fzf(lenses.write({ "hello", "world" })),
      bindings = { ["<a-cr>"] = actions.refine },
    })

    my_user:focus("input")

    my_user:sees_text_in("results", { "hello", "world" })

    my_user:keystroke("o", "i")
    my_user:keystroke("<a-cr>", "i")

    my_user:sees_text_in("input", { "o > " })
    my_user:sees_text_in("results", { "hello", "world" })

    my_user:keystroke("he", "i")
    my_user:keystroke("<a-cr>", "i")

    my_user:sees_text_in("input", { "o | he > " })
    my_user:sees_text_in("results", { "hello" })
  end)

  it("refine_with", function()
    local new_parser = function(data)
      return { text = "~" .. data.text .. "~" }
    end

    local new_lens = function(...)
      return {
        fun = function(flow, request)
          flow.spawn({ cmd = "grep", args = { request.text } })
        end,
        inputs = { ... },
      }
    end

    my_user = user.open_finder({
      lens = lenses.fzf(lenses.write({ "hello", "heello" })),
      bindings = {
        ["<a-cr>"] = actions.refine_with(new_lens, new_parser, "~> "),
      },
    })

    my_user:focus("input")

    my_user:sees_text_in("results", { "hello", "heello" })

    my_user:keystroke("o", "i")
    my_user:keystroke("<a-cr>", "i")

    my_user:sees_text_in("input", { "~> " })
    my_user:sees_text_in("results", { "~hello~", "~heello~" })

    my_user:keystroke("hel", "i")
    my_user:keystroke("<a-cr>", "i")

    my_user:sees_text_in("input", { "~> " })
    my_user:sees_text_in("results", { "~hello~" })
  end)
end)
