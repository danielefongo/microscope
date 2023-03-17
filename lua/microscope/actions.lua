local actions = {}

function actions.previous(microscope)
  local actual_cursor = microscope.results:get_cursor()
  local cursor = { actual_cursor[1] - 1, actual_cursor[2] }
  microscope.results:set_cursor(cursor)
end

function actions.next(microscope)
  local actual_cursor = microscope.results:get_cursor()
  local cursor = { actual_cursor[1] + 1, actual_cursor[2] }
  microscope.results:set_cursor(cursor)
end

function actions.scroll_down(microscope)
  local actual_cursor = microscope.preview:get_cursor()
  local cursor = { actual_cursor[1] + 10, actual_cursor[2] }
  microscope.preview:set_cursor(cursor)
end

function actions.scroll_up(microscope)
  local actual_cursor = microscope.preview:get_cursor()
  local cursor = { actual_cursor[1] - 10, actual_cursor[2] }
  microscope.preview:set_cursor(cursor)
end

function actions.toggle_full_screen(microscope)
  microscope:toggle_full_screen()
end

function actions.open(microscope)
  microscope.results:open()
end

function actions.select(microscope)
  microscope.results:select()
  actions.next(microscope)
end

function actions.close(microscope)
  microscope:close()
end

function actions.nothing(_) end

return actions
