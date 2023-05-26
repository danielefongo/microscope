local display = require("microscope.api.display")
local layouts = {}

function layouts.default(opts)
  local size = (opts.full_screen and opts.ui_size) or opts.finder_size

  if not opts.preview then
    return display
      .horizontal({
        display.space("20%"),
        display.vertical({ display.input(1), display.results() }),
        display.space("20%"),
      })
      :build(size)
  end

  if opts.ui_size.width < opts.finder_size.width then
    return display.vertical({ display.input(1), display.results(), display.preview() }):build(size)
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
