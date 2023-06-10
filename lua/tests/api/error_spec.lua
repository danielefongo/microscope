local helpers = require("tests.helpers")
local error = require("microscope.api.error")
local events = require("microscope.events")

describe("error", function()
  helpers.setup()

  it("generic error", function()
    local spy = helpers.spy_event_handler(events.event.error)

    error.generic("error message")

    helpers.wait(10)

    assert.spy(spy).was.called_with({
      critical = false,
      message = "error message",
    })
  end)

  it("critical error", function()
    local spy = helpers.spy_event_handler(events.event.error)

    error.critical("error message")

    helpers.wait(10)

    assert.spy(spy).was.called_with({
      critical = true,
      message = "error message",
    })
  end)
end)
