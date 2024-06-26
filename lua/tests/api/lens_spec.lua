local helpers = require("tests.helpers")
local lens = require("microscope.api.lens")
local command = require("microscope.api.command")

local hello_world_spec = {
  fun = function(flow)
    flow.consume(command.shell("echo", { "hello\nworld" }))
  end,
}

local function write(data)
  return {
    fun = function(flow)
      flow.write(data)
    end,
  }
end

local function write_n_times(data, times)
  return {
    fun = function(flow)
      for _ = 1, times, 1 do
        flow.write(data)
      end
    end,
  }
end

describe("lens", function()
  helpers.setup()

  it("returns nothing if no request is fed", function()
    local my_lens = lens.new({
      fun = function(flow)
        flow.write({ "hello", "world" })
      end,
    })

    assert.are.same(helpers.consume_lens(my_lens), nil)
  end)

  it("returns nothing if no lens is stopped", function()
    local my_lens = lens.new({
      fun = function(flow)
        flow.write({ "hello", "world" })
      end,
    })

    my_lens:feed("")
    my_lens:stop()

    assert.are.same(helpers.consume_lens(my_lens), nil)
  end)

  it("returns nothing if nothing is written", function()
    local my_lens = lens.new({
      fun = function() end,
    })

    my_lens:feed("")

    assert.are.same(helpers.consume_lens(my_lens), nil)
  end)

  describe("request", function()
    it("can be obtained and changed in flow function", function()
      local my_lens = lens.new({
        fun = function(_, req)
          req.count = req.count + 1
        end,
      })

      local request = { count = 0 }
      my_lens:feed(request)
      helpers.consume_lens(my_lens)

      assert.are.same(request.count, 1)
    end)
  end)

  describe("context", function()
    it("is kept between searches", function()
      local my_lens = lens.new({
        fun = function(flow, _, context)
          if context.data then
            return flow.write(context.data)
          end

          flow.write("hello\n")
          context.data = "world\n"
        end,
      })

      my_lens:feed("")
      local out1 = helpers.consume_lens(my_lens)
      my_lens:feed("")
      local out2 = helpers.consume_lens(my_lens)

      assert.are.same(out1 .. out2, "hello\nworld\n")
    end)
  end)

  describe("args", function()
    it("defaults", function()
      local my_lens = lens.new({
        fun = function(flow, _, args, _)
          flow.write(args.text1)
          flow.write(args.text2)
        end,
        args = {
          text1 = "hello\n",
          text2 = "world\n",
        },
      })

      my_lens:feed("")
      local out = helpers.consume_lens(my_lens)

      assert.are.same(out, "hello\nworld\n")
    end)

    it("override", function()
      local my_lens = lens.new({
        fun = function(flow, _, args, _)
          flow.write(args.text1)
          flow.write(args.text2)
        end,
        args = {
          text1 = "hello\n",
          text2 = "world\n",
        },
      })

      my_lens:set_args({
        text2 = "madworld\n",
      })
      my_lens:feed("")
      local out = helpers.consume_lens(my_lens)

      assert.are.same(out, "hello\nmadworld\n")
    end)

    it("override nested", function()
      local my_lens = lens.new({
        fun = function(flow, _, args, _)
          flow.write(args.text1)
          flow.write(args.inner.text2)
        end,
        args = {
          text1 = "hello\n",
          inner = {
            text2 = "world\n",
          },
        },
      })

      my_lens:set_args({
        inner = {
          text2 = "madworld\n",
        },
      })
      my_lens:feed("")
      local out = helpers.consume_lens(my_lens)

      assert.are.same(out, "hello\nmadworld\n")
    end)

    it("validate", function()
      local my_lens = lens.new({
        fun = function() end,
        args = {
          text1 = "hello\n",
          text2 = "world\n",
        },
      })

      local new_args = my_lens:set_args({
        text2 = "madworld\n",
      })
      local nil_new_args, defaults = my_lens:set_args({
        text2 = 42,
      })

      assert.are.same(new_args, {
        text1 = "hello\n",
        text2 = "madworld\n",
      })

      assert.are.same(nil_new_args, nil)
      assert.are.same(defaults, {
        text1 = "hello\n",
        text2 = "world\n",
      })
    end)

    it("validate nested", function()
      local my_lens = lens.new({
        fun = function() end,
        args = {
          nested = { text1 = "hello\n" },
        },
      })

      local new_args = my_lens:set_args({
        nested = { text1 = "xxx\n" },
      })
      local nil_new_args, defaults = my_lens:set_args({
        nested = { text1 = 42 },
      })

      assert.are.same(new_args, {
        nested = { text1 = "xxx\n" },
      })

      assert.are.same(nil_new_args, nil)
      assert.are.same(defaults, {
        nested = { text1 = "hello\n" },
      })
    end)
  end)

  describe("flow", function()
    describe("write", function()
      it("returns data using a string", function()
        local my_lens = lens.new({
          fun = function(flow)
            flow.write("hello\nworld\n")
          end,
        })

        my_lens:feed("")

        assert.are.same(helpers.consume_lens(my_lens), "hello\nworld\n")
      end)

      it("returns data using an array", function()
        local my_lens = lens.new({
          fun = function(flow)
            flow.write({ "hello", "world" })
          end,
        })

        my_lens:feed("")

        assert.are.same(helpers.consume_lens(my_lens), "hello\nworld\n")
      end)
    end)

    describe("command", function()
      it("with into", function()
        local my_lens = lens.new({
          fun = function(flow)
            flow.consume(command.iter(flow.read_iter()):pipe("grep", { "hel" }))
          end,
          inputs = { hello_world_spec },
        })

        my_lens:feed("")

        assert.are.same(helpers.consume_lens(my_lens), "hello\n")
      end)

      it("with collect", function()
        local my_lens = lens.new({
          fun = function(flow)
            local result = flow.collect(command.iter(flow.read_iter()):pipe("grep", { "hel" }))
            flow.write(result)
          end,
          inputs = { hello_world_spec },
        })

        my_lens:feed("")

        assert.are.same(helpers.consume_lens(my_lens), "hello\n")
      end)
    end)

    describe("stop", function()
      it("interrupts a flow", function()
        local my_lens = lens.new({
          fun = function(flow)
            flow.write("hello\n")
            flow.stop()
            flow.write("world\n")
          end,
          inputs = {},
        })

        my_lens:feed("")

        assert.are.same(helpers.consume_lens(my_lens), "hello\n")
      end)

      it("returns data using an array", function()
        local my_lens = lens.new({
          fun = function(flow)
            flow.write({ "hello", "world" })
          end,
          inputs = {},
        })

        my_lens:feed("")

        assert.are.same(helpers.consume_lens(my_lens), "hello\nworld\n")
      end)
    end)

    describe("read", function()
      it("consumes simple input lens", function()
        local my_lens = lens.new({
          fun = function(_) end,
          inputs = { write("hello\nworld\n") },
        })

        my_lens:feed("")

        assert.are.same(my_lens.flow.read(), "hello\nworld\n")
        assert.are.same(my_lens.flow.read(), nil)
      end)

      it("consumes chunked input lens", function()
        local my_lens = lens.new({
          fun = function(_) end,
          inputs = { write_n_times("hello\nworld\n", 3) },
        })

        my_lens:feed("")

        assert.are.same(my_lens.flow.read(), "hello\nworld\n")
        assert.are.same(my_lens.flow.read(), "hello\nworld\n")
        assert.are.same(my_lens.flow.read(), "hello\nworld\n")
        assert.are.same(my_lens.flow.read(), nil)
      end)

      it("consumes multiple input lenses", function()
        local my_lens = lens.new({
          fun = function(_) end,
          inputs = { write("hello\n"), write("world\n") },
        })

        my_lens:feed("")

        assert.are.same(my_lens.flow.read(), "hello\n")
        assert.are.same(my_lens.flow.read(), "world\n")
        assert.are.same(my_lens.flow.read(), nil)
      end)
    end)

    describe("read_array", function()
      it("consumes simple input lens", function()
        local my_lens = lens.new({
          fun = function(_) end,
          inputs = { write("hello\nworld\n") },
        })

        my_lens:feed("")

        assert.are.same(my_lens.flow.read_array(), { "hello", "world" })
        assert.are.same(my_lens.flow.read(), nil)
      end)
    end)

    describe("read_iter", function()
      it("consumes simple input lens", function()
        local my_lens = lens.new({
          fun = function(_) end,
          inputs = {
            write("hello\n"),
            write("world\n"),
          },
        })

        my_lens:feed("")

        local results = {}
        for out in my_lens.flow.read_iter() do
          table.insert(results, out)
        end
        assert.are.same(results, { "hello\n", "world\n" })
      end)
    end)

    describe("read_array_iter", function()
      it("consumes simple input lens", function()
        local my_lens = lens.new({
          fun = function(_) end,
          inputs = {
            write("hello\n"),
            write("world\n"),
          },
        })

        my_lens:feed("")

        local results = {}
        for out in my_lens.flow.read_array_iter() do
          table.insert(results, out)
        end
        assert.are.same(results, { { "hello" }, { "world" } })
      end)
    end)
  end)
end)
