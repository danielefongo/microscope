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

  describe("hl_match_with", function()
    it("applies no highlights if no match", function()
      local hi = highlight.new({}, "abc")
      hi:hl_match_with(function()
        return { [1] = { { color = color.color1, from = 1, to = 2 } } }
      end, "(d)(.*)", 1)
      assert.are.same(hi:get_highlights(), {})
    end)

    it("applies highlights from function", function()
      local hi = highlight.new({}, "abc")
      hi:hl_match_with(function()
        return { [1] = { { color = color.color1, from = 1, to = 1 } } }
      end, "(a)(.*)", 1)
      assert.are.same(hi:get_highlights(), {
        { color = color.color1, from = 1, to = 1 },
      })
    end)

    it("adjusts highlights position based on group position", function()
      local hi = highlight.new({}, "abc")
      hi:hl_match_with(function()
        return { [1] = { { color = color.color1, from = 1, to = 1 } } }
      end, "(a)(bc)", 2)
      assert.are.same(hi:get_highlights(), {
        { color = color.color1, from = 2, to = 2 },
      })
    end)

    it("applies multiple highlights from function", function()
      local hi = highlight.new({}, "abcdef")
      hi:hl_match_with(function()
        return {
          [1] = {
            { color = color.color1, from = 1, to = 1 },
            { color = color.color2, from = 2, to = 3 },
          },
        }
      end, "(abc)(def)", 2)
      assert.are.same(hi:get_highlights(), {
        { color = color.color1, from = 4, to = 4 },
        { color = color.color2, from = 5, to = 6 },
      })
    end)

    it("combines with other highlight methods", function()
      local hi = highlight.new({}, "abcdefg")
      hi:hl(color.color3, 1, 2):hl_match(color.color2, "(abc)(def)(g)", 2):hl_match_with(function()
        return { [1] = { { color = color.color1, from = 2, to = 3 } } }
      end, "(ab)(cd)(efg)", 3)

      assert.are.same(hi:get_highlights(), {
        { color = color.color3, from = 1, to = 2 },
        { color = color.color2, from = 4, to = 5 },
        { color = color.color1, from = 6, to = 7 },
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
