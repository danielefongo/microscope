local constants = require("microscope.constants")
local actions = {}

function actions.previous(microscope)
  microscope.results:focus(constants.UP)
  microscope:show_preview()
end

function actions.next(microscope)
  microscope.results:focus(constants.DOWN)
  microscope:show_preview()
end

function actions.scroll_down(microscope)
  microscope.preview:scroll(constants.DOWN, 10)
end

function actions.scroll_up(microscope)
  microscope.preview:scroll(constants.UP, 10)
end

function actions.open(microscope)
  microscope.results:open()
  microscope:close()
end

function actions.close(microscope)
  microscope:close()
end

return actions
