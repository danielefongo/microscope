local helpers = require("tests.helpers")
local highlight = require("microscope.api.highlight")
local color = highlight.color

local function assert_hl_match(text, data, expectation)
  local hi = highlight.new({}, text)
  for _, element in pairs(data) do
    hi:hl_match(element.color, element.pattern, element.group)
  end

  assert.are.same(hi:get_highlights(), expectation)
end

local function assert_hl(text, data, expectation)
  local hi = highlight.new({}, text)
  for _, element in pairs(data) do
    hi:hl(element.color, element.from, element.to)
  end

  assert.are.same(hi:get_highlights(), expectation)
end

describe("highlight", function()
  helpers.setup()

  describe("hl match", function()
    it("no highlights if no match", function()
      assert_hl_match("abc", {
        { color = color.color1, pattern = "(d)(%w+)", group = 1 },
      }, {})

      assert_hl_match("abc", {
        { color = color.color1, pattern = "(abc)(.+)", group = 2 },
      }, {})
    end)

    it("find by group", function()
      assert_hl_match("abc", {
        { color = color.color1, pattern = "(%w+)", group = 1 },
      }, {
        { color = color.color1, from = 1, to = 3 },
      })

      assert_hl_match("abc", {
        { color = color.color1, pattern = "(a)(%w+)", group = 1 },
      }, {
        { color = color.color1, from = 1, to = 1 },
      })

      assert_hl_match("abc", {
        { color = color.color1, pattern = "(a)(%w+)(c)", group = 2 },
      }, {
        { color = color.color1, from = 2, to = 2 },
      })

      assert_hl_match("abc", {
        { color = color.color1, pattern = "(a)(%w+)", group = 2 },
      }, {
        { color = color.color1, from = 2, to = 3 },
      })
    end)

    it("multiple highlights", function()
      assert_hl_match("abc", {
        { color = color.color1, pattern = "(%w+)(%w+)(%w+)", group = 1 },
        { color = color.color2, pattern = "(%w+)(%w+)(%w+)", group = 2 },
        { color = color.color3, pattern = "(%w)(%w)(%w)", group = 3 },
      }, {
        { color = color.color1, from = 1, to = 1 },
        { color = color.color2, from = 2, to = 2 },
        { color = color.color3, from = 3, to = 3 },
      })
    end)
  end)

  describe("hl", function()
    it("find by range", function()
      assert_hl("abc", {
        { color = color.color1, from = 1, to = 1 },
      }, {
        { color = color.color1, from = 1, to = 1 },
      })

      assert_hl("abc", {
        { color = color.color1, from = 1 },
      }, {
        { color = color.color1, from = 1, to = 1 },
      })
    end)

    it("multiple highlights", function()
      assert_hl("abc", {
        { color = color.color1, from = 1, to = 1 },
        { color = color.color2, from = 2, to = 3 },
      }, {
        { color = color.color1, from = 1, to = 1 },
        { color = color.color2, from = 2, to = 3 },
      })
    end)
  end)

  it("hl+hl_match", function()
    local hi = highlight.new({}, "abc")
    hi:hl_match(color.color1, "(a)(.*)", 1)
    hi:hl(color.color2, 2)

    assert.are.same(hi:get_highlights(), {
      { color = color.color1, from = 1, to = 1 },
      { color = color.color2, from = 2, to = 2 },
    })
  end)

  it("hl overrides", function()
    local hi = highlight.new({}, "abcde")
    hi:hl_match(color.color1, "(ab)(.*)", 1)
      :hl_match(color.color2, "(.*)(cde)", 2)
      :hl_match(color.color3, "(.*)(bcd)(.*)", 2)

    assert.are.same(hi:get_highlights(), {
      { color = color.color1, from = 1, to = 1 },
      { color = color.color2, from = 5, to = 5 },
      { color = color.color3, from = 2, to = 4 },
    })
  end)
end)
