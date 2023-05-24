local display = require("microscope.api.display")
local layouts = {}

function layouts.default(opts)
  if opts.ui_rectangle.width <= opts.finder_rectangle.width or not opts.has_preview then
    return display
      .horizontal({
        display.space("25%"),
        display.vertical({ display.input(1), display.results() }),
        display.space("25%"),
      })
      :build(opts.finder_rectangle)
  else
    return display
      .horizontal({
        display.vertical({ display.input(1), display.results() }, "50%"),
        display.preview(),
      })
      :build(opts.finder_rectangle)
  end
end

return layouts
