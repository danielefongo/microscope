local helpers = require("tests.helpers")
local parsers = require("microscope.builtin.parsers")
local highlight = require("microscope.api.highlight")

describe("parsers", function()
  helpers.setup()

  describe("fuzzy", function()
    it("get no highlights without request or valid text", function()
      assert.are.same(parsers.fuzzy({ text = "abcde" }, { text = "" }).highlights, {})
      assert.are.same(parsers.fuzzy({ text = "" }, { text = "abc" }).highlights, {})
    end)

    it("get right highlights when request and text are the same", function()
      assert.are.same(parsers.fuzzy({ text = "abc" }, { text = "abc" }).highlights, {
        { color = highlight.color.match, from = 1, to = 1 },
        { color = highlight.color.match, from = 2, to = 2 },
        { color = highlight.color.match, from = 3, to = 3 },
      })
    end)

    it("get right highlights when consecutive", function()
      assert.are.same(parsers.fuzzy({ text = "abcde" }, { text = "abc" }).highlights, {
        { color = highlight.color.match, from = 1, to = 1 },
        { color = highlight.color.match, from = 2, to = 2 },
        { color = highlight.color.match, from = 3, to = 3 },
      })
    end)

    it("get right highlights when not consecutive", function()
      assert.are.same(parsers.fuzzy({ text = "abcde" }, { text = "ace" }).highlights, {
        { color = highlight.color.match, from = 1, to = 1 },
        { color = highlight.color.match, from = 3, to = 3 },
        { color = highlight.color.match, from = 5, to = 5 },
      })
    end)

    it("get right highlights with case sensitive", function()
      assert.are.same(parsers.fuzzy({ text = "abCde" }, { text = "Cd" }).highlights, {
        { color = highlight.color.match, from = 3, to = 3 },
        { color = highlight.color.match, from = 4, to = 4 },
      })
    end)

    it("get right highlights with a dot", function()
      assert.are.same(parsers.fuzzy({ text = "ab.de" }, { text = ".d" }).highlights, {
        { color = highlight.color.match, from = 3, to = 3 },
        { color = highlight.color.match, from = 4, to = 4 },
      })
    end)

    it("get right highlights with an entire word", function()
      assert.are.same(parsers.fuzzy({ text = "ab de" }, { text = "ab" }).highlights, {
        { color = highlight.color.match, from = 1, to = 1 },
        { color = highlight.color.match, from = 2, to = 2 },
      })
    end)
  end)
end)
