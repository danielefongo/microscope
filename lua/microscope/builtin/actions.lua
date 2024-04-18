local lenses = require("microscope.builtin.lenses")
local parsers = require("microscope.builtin.parsers")
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
  microscope:alter(function(opts)
    opts.full_screen = not opts.full_screen
    return opts
  end)
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

function actions.alter(opts)
  return function(microscope)
    microscope:alter(function(old_opts)
      return vim.tbl_deep_extend("force", old_opts, opts)
    end)
  end
end

function actions.set_layout(layout)
  return actions.alter({ layout = layout })
end

function actions.set_args(args)
  return actions.alter({ args = args })
end

function actions.refine_with(lens, lens_parser, prompt)
  return function(microscope)
    local current_search = microscope.input:text()
    local current_results = microscope.results:raw_results()

    if current_search == "" or #current_results == 0 then
      return
    end

    microscope:alter(function(opts)
      local new_parsers = {}
      for _, parser in ipairs(opts.parsers or {}) do
        new_parsers[parser] = parser
      end
      new_parsers[lens_parser] = lens_parser

      opts.parsers = vim.tbl_values(new_parsers)
      opts.lens = lens(lenses.write(current_results))

      opts.searches = opts.searches or {}
      table.insert(opts.searches, current_search)

      opts.prompt = prompt or table.concat(opts.searches, " | ") .. " > "

      return opts
    end)

    microscope.input:reset()
  end
end

function actions.refine(microscope)
  actions.refine_with(lenses.fzf, parsers.fuzzy)(microscope)
end

function actions.nothing(_) end

return actions
