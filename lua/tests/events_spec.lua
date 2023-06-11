local helpers = require("tests.helpers")

local events = require("microscope.events")

describe("events", function()
  local my_events

  helpers.setup({ defer_fn = false })

  before_each(function()
    my_events = events.new()
  end)

  it("fire and listen to events", function()
    local handler = helpers.spy_event_handler(my_events, "module", events.event.result_focused)
    local handler2 = helpers.spy_event_handler(my_events, "module", events.event.input_changed)

    my_events:fire(events.event.result_focused, { text = "hello" })
    my_events:fire(events.event.input_changed, { text = "world" })

    helpers.wait(10)

    assert.spy(handler).was.called(1)
    assert.spy(handler).was.called_with({ text = "hello" })

    assert.spy(handler2).was.called(1)
    assert.spy(handler2).was.called_with({ text = "world" })
  end)

  it("fire and listen to native events", function()
    local handler = helpers.spy_native_event_handler(my_events, "module", events.event.cursor_moved)
    local handler2 = helpers.spy_native_event_handler(my_events, "module", events.event.win_leave)

    my_events:fire_native(events.event.cursor_moved)
    my_events:fire_native(events.event.win_leave)

    helpers.wait(10)

    assert.spy(handler).was.called(1)
    assert.spy(handler2).was.called(1)
  end)

  it("fire and listen to delayed events", function()
    local handler = helpers.spy_event_handler(my_events, "module", events.event.result_focused)

    my_events:fire(events.event.result_focused, { text = "hello" }, 10)

    helpers.wait(20)

    assert.spy(handler).was.called(1)
    assert.spy(handler).was.called_with({ text = "hello" })
  end)

  it("do not fire twice delayed events that are not handled yet", function()
    local handler = helpers.spy_event_handler(my_events, "module", events.event.result_focused)

    my_events:fire(events.event.result_focused, { text = "hello" }, 10)
    my_events:fire(events.event.result_focused, { text = "hello" }, 10)
    my_events:fire(events.event.result_focused, { text = "hello" }, 10)
    my_events:fire(events.event.result_focused, { text = "world" }, 10)

    helpers.wait(20)

    assert.spy(handler).was.called(1)
    assert.spy(handler).was.called_with({ text = "world" })
  end)

  it("cancel ongoing event", function()
    local handler = helpers.spy_event_handler(my_events, "module", events.event.result_focused)

    my_events:fire(events.event.result_focused, { text = "hello" }, 10)
    my_events:cancel(events.event.result_focused)

    helpers.wait(20)

    assert.spy(handler).was_not.called()
  end)

  it("cancel not scheduled event handler", function()
    my_events:clear("module", events.event.result_focused)
    my_events:fire(events.event.result_focused, { text = "hello" }, 10)
  end)

  it("cancel specific event handler", function()
    local handler = helpers.spy_event_handler(my_events, "module", events.event.result_focused)

    my_events:clear("module", events.event.result_focused)
    my_events:fire(events.event.result_focused, { text = "hello" }, 10)

    helpers.wait(20)

    assert.spy(handler).was_not.called()
  end)

  it("cancel all event handlers for specific module", function()
    local handler = helpers.spy_event_handler(my_events, "module", events.event.result_focused)
    local handler2 = helpers.spy_event_handler(my_events, "module", events.event.input_changed)

    my_events:clear_module("module")
    my_events:fire(events.event.result_focused, { text = "hello" }, 10)
    my_events:fire(events.event.input_changed, { text = "hello" }, 10)

    helpers.wait(20)

    assert.spy(handler).was_not.called()
    assert.spy(handler2).was_not.called()
  end)

  it("do not infer with other events instances", function()
    local handler = helpers.spy_event_handler(my_events, "module", events.event.result_focused)

    local my_events2 = events.new()

    my_events2:fire(events.event.result_focused, { text = "hello" }, 10)

    helpers.wait(20)

    assert.spy(handler).was_not.called()
  end)
end)
