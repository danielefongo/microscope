local constants = require("microscope.constants")
local actions = {}

function actions.previous(microscope)
  microscope.results:focus(constants.UP)
end

function actions.next(microscope)
  microscope.results:focus(constants.DOWN)
end

function actions.scroll_down(microscope)
  microscope.preview:scroll(constants.DOWN, 10)
end

function actions.scroll_up(microscope)
  microscope.preview:scroll(constants.UP, 10)
end

function actions.open(microscope)
  microscope.results:open()
end

function actions.select(microscope)
  microscope.results:select()
  microscope.results:focus(constants.DOWN)
end

function actions.close(microscope)
  microscope:close()
end

return actions
