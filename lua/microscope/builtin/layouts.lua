local display = require("microscope.api.display")
local layouts = {}

function layouts.default(opts)
  local size
  if opts.full_screen then
    size = opts.ui_size
  else
    size = opts.finder_size
  end

  if opts.ui_size.width < opts.finder_size.width or not opts.preview then
    return display
      .horizontal({
        display.space("20%"),
        display.vertical({ display.input(1), display.results() }),
        display.space("20%"),
      })
      :build(size)
  else
    return display
      .horizontal({
        display.vertical({ display.input(1), display.results() }, "50%"),
        display.preview(),
      })
      :build(size)
  end
end

return layouts
