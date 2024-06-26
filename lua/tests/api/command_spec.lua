local helpers = require("tests.helpers")
local cmd = require("microscope.api.command")

local function consume_command(iter, time)
  local final_out

  local async = vim.loop.new_idle()
  async:start(function()
    local my_out = iter()

    if my_out == nil then
      return async:stop()
    end
    final_out = (final_out or "") .. my_out
  end)

  helpers.wait(time or 10)

  return final_out
end

describe("command", function()
  helpers.setup()

  it("shell", function()
    local mycmd = cmd.shell("echo", { "hello\nworld" })

    local output = consume_command(mycmd:get_iter())
    assert.are.same(output, "hello\nworld\n")
  end)

  it("iterator", function()
    local elements = { "hello\n", "world\n" }
    local iterator = function()
      return table.remove(elements, 1)
    end

    local mycmd = cmd.iter(iterator)

    local output = consume_command(mycmd:get_iter())
    assert.are.same(output, "hello\nworld\n")
  end)

  it("const", function()
    local mycmd = cmd.const("hello\n")

    local output = consume_command(mycmd:get_iter())
    assert.are.same(output, "hello\n")
  end)

  it("fn", function()
    local mycmd = cmd.fn(function(x)
      return x
    end, "hello\n")

    local output = consume_command(mycmd:get_iter())
    assert.are.same(output, "hello\n")
  end)

  it("await", function()
    local mycmd = cmd.await(function(callback, x)
      callback(x)
    end, "hello\n")

    local output = consume_command(mycmd:get_iter())
    assert.are.same(output, "hello\n")
  end)

  describe("filter", function()
    it("from shell", function()
      local filter = function(data)
        return string.gsub(data, "hello", "hallo")
      end

      local mycmd = cmd.shell("echo", { "hello" }):filter(filter)

      local output = consume_command(mycmd:get_iter())
      assert.are.same(output, "hallo\n")
    end)

    it("from iterator", function()
      local elements = { "hello\n" }
      local iterator = function()
        return table.remove(elements, 1)
      end

      local filter = function(data)
        return string.gsub(data, "hello", "hallo")
      end

      local mycmd = cmd.iter(iterator):filter(filter)

      local output = consume_command(mycmd:get_iter())
      assert.are.same(output, "hallo\n")
    end)
  end)

  describe("pipe", function()
    it("from shell", function()
      local mycmd = cmd.shell("echo", { "hello\nworld" }):pipe("grep", { "he" })

      local output = consume_command(mycmd:get_iter())
      assert.are.same(output, "hello\n")
    end)

    it("from iter", function()
      local elements = { "hello\n", "world\n" }
      local iterator = function()
        return table.remove(elements, 1)
      end

      local mycmd = cmd.iter(iterator):pipe("grep", { "he" })

      local output = consume_command(mycmd:get_iter())
      assert.are.same(output, "hello\n")
    end)

    it("from another pipe", function()
      local elements = { "hello\n", "world\n", "heello\n" }
      local iterator = function()
        return table.remove(elements, 1)
      end

      local mycmd = cmd.iter(iterator):pipe("grep", { "he" }):pipe("head", { "--lines", 1 })

      local output = consume_command(mycmd:get_iter())
      assert.are.same(output, "hello\n")
    end)
  end)

  it("array", function()
    local mycmd = cmd.fn(function(x)
      return x
    end, { "hello" })

    local output = consume_command(mycmd:get_iter())
    assert.are.same(output, "hello\n")
  end)
end)
