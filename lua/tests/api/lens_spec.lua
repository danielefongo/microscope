local helpers = require("tests.helpers")
local lens = require("microscope.api.lens")

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
  helpers.eventually_store_coverage()

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

    it("fn", function()
      local my_lens = lens.new({
        fun = function(flow)
          local data = flow.fn(function(x)
            return x
          end, "hello\n")
          flow.write(data)
        end,
      })

      my_lens:feed("")

      assert.are.same(helpers.consume_lens(my_lens), "hello\n")
    end)

    it("await", function()
      local my_lens = lens.new({
        fun = function(flow)
          local data = flow.await(function(callback, x)
            callback(x)
          end, "hello\n")
          flow.write(data)
        end,
      })

      my_lens:feed("")

      assert.are.same(helpers.consume_lens(my_lens), "hello\n")
    end)

    it("spawn", function()
      local my_lens = lens.new({
        fun = function(flow)
          flow.spawn({ cmd = "echo", args = { "hello\nworld" } })
        end,
      })

      my_lens:feed("")

      assert.are.same(helpers.consume_lens(my_lens, 100), "hello\nworld\n")
    end)

    it("command", function()
      local my_lens = lens.new({
        fun = function(flow)
          local out = flow.command({ cmd = "echo", args = { "hello\nworld" } })
          flow.write(out)
        end,
      })

      my_lens:feed("")

      assert.are.same(helpers.consume_lens(my_lens, 100), "hello\nworld\n")
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
