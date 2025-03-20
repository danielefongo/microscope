local helpers = require("tests.helpers")
local treesitter = require("microscope.api.treesitter")

describe("treesitter", function()
  local buf

  helpers.setup({ defer_fn = false })

  before_each(function()
    buf = vim.api.nvim_create_buf(false, true)
  end)

  after_each(function()
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end)

  local function set_buf_content(content)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
  end

  it("unsupported language", function()
    local content = "test"
    local expected = {}

    set_buf_content(content)

    assert.same(treesitter.for_buffer(buf, "nonexistent_language"), expected)
    assert.same(treesitter.for_text(content, "nonexistent_language"), expected)
    assert.same(treesitter.for_buffer(buf, nil), expected)
    assert.same(treesitter.for_text(content, nil), expected)
  end)

  it("single line content", function()
    local content = "local x = 42"
    local expected = {
      {
        { color = "@keyword.lua", from = 1, to = 5 },
        { color = "@variable.lua", from = 7, to = 7 },
        { color = "@operator.lua", from = 9, to = 9 },
        { color = "@number.lua", from = 11, to = 12 },
      },
    }

    set_buf_content(content)

    assert.are.same(treesitter.for_buffer(buf, "lua"), expected)
    assert.are.same(treesitter.for_text(content, "lua"), expected)
  end)

  it("multiline content", function()
    local content = [[
local function test()
  print("Hello")
end
]]
    local expected = {
      {
        { color = "@keyword.lua", from = 1, to = 5 },
        { color = "@keyword.function.lua", from = 7, to = 14 },
        { color = "@variable.lua", from = 16, to = 19 },
        { color = "@function.lua", from = 16, to = 19 },
        { color = "@punctuation.bracket.lua", from = 20, to = 20 },
        { color = "@punctuation.bracket.lua", from = 21, to = 21 },
      },
      {
        { color = "@variable.lua", from = 3, to = 7 },
        { color = "@function.call.lua", from = 3, to = 7 },
        { color = "@function.builtin.lua", from = 3, to = 7 },
        { color = "@punctuation.bracket.lua", from = 8, to = 8 },
        { color = "@string.lua", from = 9, to = 15 },
        { color = "@punctuation.bracket.lua", from = 16, to = 16 },
      },
      { { color = "@keyword.function.lua", from = 1, to = 3 } },
    }

    set_buf_content(content)

    assert.are.same(treesitter.for_buffer(buf, "lua"), expected)
    assert.are.same(treesitter.for_text(content, "lua"), expected)
  end)

  it("multiline nodes", function()
    local content = [[
local message = [=[
  This is a string
  across multiple
  lines
]=]
]]
    local expected = {
      {
        { color = "@keyword.lua", from = 1, to = 5 },
        { color = "@variable.lua", from = 7, to = 13 },
        { color = "@operator.lua", from = 15, to = 15 },
        { color = "@string.lua", from = 17, to = 20 },
      },
      { { color = "@string.lua", from = 1, to = 18 } },
      { { color = "@string.lua", from = 1, to = 17 } },
      { { color = "@string.lua", from = 1, to = 7 } },
      { { color = "@string.lua", from = 1, to = 3 } },
    }

    set_buf_content(content)

    assert.are.same(treesitter.for_buffer(buf, "lua"), expected)
    assert.are.same(treesitter.for_text(content, "lua"), expected)
  end)
end)
