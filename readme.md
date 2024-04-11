# Microscope

![ci](https://img.shields.io/github/actions/workflow/status/danielefongo/microscope/ci.yml?style=for-the-badge)
![code-coverage](https://img.shields.io/codecov/c/github/danielefongo/microscope?style=for-the-badge)

A micro and highly composable finder for Neovim with no dependencies.

## Disclaimer

Please note that this project is still under development, so the API may change.

## Base setup

On [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "danielefongo/microscope",
  dependencies = {
    "danielefongo/microscope-files",
    "danielefongo/microscope-buffers",
  },
  config = function()
    local microscope = require("microscope")
    local actions = require("microscope.builtin.actions")
    local layouts = require("microscope.builtin.layouts")

    local files = require("microscope-files")
    local buffers = require("microscope-buffers")

    microscope.setup({
      prompt = ":> " -- optional (default is "> ")
      size = {
        width = 80,
        height = 30,
      },
      layout = layouts.default,
      bindings = {
        ["<c-j>"] = actions.next,
        ["<c-k>"] = actions.previous,
        ["<a-j>"] = actions.scroll_down,
        ["<a-k>"] = actions.scroll_up,
        ["<cr>"] = actions.open,
        ["<esc>"] = actions.close,
        ["<tab>"] = actions.select,
        ["<c-f>"] = actions.toggle_full_screen,
        ["<a-s>"] = actions.refine,
      },
    })

    microscope.register(files.finders)
    microscope.register(buffers.finders)

    -- Bind using microscope instance
    vim.keymap.set("n", "<leader>of", microscope.finders.file:bind())
    vim.keymap.set("n", "<leader>oo", microscope.finders.old_file:bind())

    -- Bind using microscope commands
    vim.keymap.set("n", "<leader>of", ":Microscope file<cr>")
    vim.keymap.set("n", "<leader>oo", ":Microscope old_file<cr>")
  end,
}
```

You can create your own [finder](#finder).

## Finder

Each finder can be defined using the following options:

```lua
local opts = {
  lens = lens_spec, -- required
  parsers = list_of_parsers, -- optional
  open = open_fn, -- optional
  preview = preview_fn, -- optional
  layout = layout_fn, -- optional
  full_screen = full_screen, -- optional
  size = custom_size, -- optional (overrides/extends the microscope size option)
  bindings = custom_bindings, -- optional (overrides/extends the microscope bindings option)
  prompt = prompt, -- optional (overrides/extends the microscope prompt option)
  spinner = spinner, -- optional (overrides/extends the microscope spinner option)
}
```

These properties are explained below.

#### Creation

A finder can be created in one of two ways:

```lua
local microscope = require("microscope")

-- First way
local finder = microscope.finder(opts)

-- Second way (registers the finder as microscope.finders.name)
local finder = microscope.register({
  name = opts,
})
```

#### Binding

After creating the finder, you can use it by binding it to a shortcut. There are three ways to achieve this:

```lua
-- First way
vim.keymap.set("n", "<leader>of", finder:bind())

-- Second way
vim.keymap.set("n", "<leader>of", microscope.finders.name:bind())

-- Third way
vim.keymap.set("n", "<leader>of", ":Microscope name<cr>")
```

#### Opts override

After creating the finder, you have the option to override its opts using the `override()` method. Here's an example:

Example:

```lua
finder:override({
  size = {
    width = 30,
  },
  bindings = {
    ["<cr>"] = actions.nothing,
  },
})
```

### Lens spec

This element represents a specification for a [lens](#lens), which is used to retrieve or filter data (e.g. list of files or buffers), based on the [request](#request). It is a table that consists of a [lens function](#lens-function) and an optional list of input lens specifications.

```lua
local lens = {
  fun = function(flow, request, context)
    -- logic
  end,
  inputs = { ... }, -- optional list of other lens specs
}
```

Example:

```lua
local lenses = {}

function lenses.rg(cwd)
  return {
    fun = function(flow)
      flow.cmd.shell("rg", { "--files" }, cwd):into(flow)
    end,
  }
end

function lenses.fzf(...)
  return {
    fun = function(flow, request)
      flow.cmd.iter(flow.read_iter()):pipe("fzf", { "-f", request.text }):into(flow)
    end,
    inputs = { ... },
  }
end

local my_lens = lenses.fzf(lenses.rg())
```

### Parsers

This is a list of functions, called [parser functions](#parser-function), used to parse the data retrieved from the [lens](#lens).

#### Parser function

This function accepts result data and the original [request](#request), and transforms the data by adding extra information. The first parser will receive a data containing only the `text` field. It is important for each parser function to propagate this field, even if unmodified, as it will be used to render the result. The additional information can include things like `file` or any other custom data you wish to add. The final data table will be passed to the [open function](#open-function) and the [preview function](#preview-function).

There is another special data field called `highlights`, which should be propagated unless you intend to remove it. This field represents a list of highlights to be applied to the result. For more details, please refer to the [highlight section](#highlight).

Example:

```lua
local parser_fn = function(data, _)
  local elements = vim.split(data.text, ":", {})

  data.highlights = build_highlights(data)
  data.buffer = tonumber(elements[1])

  return data
end
```

### Open function

The open function is called when the [open action](#actions) is triggered. It takes a single result data obtained from the parsers, the [request](#request), and optional metadata (sent by `results:open`).

Example:

```lua
local open_fn = function(data, request, metadata)
  vim.cmd("e " .. data.file)
end
```

### Preview function

The preview function is called when a result is focused. It takes a single result data obtained from the parsers and the `preview` microscope instance.

Example:

```lua
local preview_fn = function(data, window)
  window:write({ data.text })
end
```

For more details about the preview window API, refer to the [preview window section](#preview-window).

### Layout function

The layout function is responsible for defining the structure of the finder using the [display](#display) API. It receives a table with the following fields:

- `finder_size`: represents the [size](#size) provided in the microscope settings.
- `ui_size`: represents the size of the entire UI.
- `preview`: indicates whether the [preview function](#preview-function) has been set or not.
- `full_screen`: indicates whether the full-screen option has been set or not.

Example:

```lua
local layout_fn = function(opts)
  return display
    .vertical({
      display.horizontal({
        display.results("40%"),
        display.preview(),
      }),
      display.input(1),
    })
    :build(opts.finder_size)
end
```

### Full screen

The `full_screen` is represented as a boolean, defaults to `false`.

### Size

The `size` is represented as a table containing `width` and `height` fields.

### Bindings

The `bindings` table is used to define shortcut bindings for microscope [actions](#action).

Example:

```lua
local actions = require("microscope.builtin.actions")

local bindings = {
  ["<c-j>"] = actions.next,
  ["<c-k>"] = actions.previous,
  ["<a-j>"] = actions.scroll_down,
  ["<a-k>"] = actions.scroll_up,
  ["<cr>"] = actions.open,
  ["<esc>"] = actions.close,
  ["<tab>"] = actions.select,
  ["<c-f>"] = actions.toggle_full_screen,
}
```

#### Action

This function accepts a [microscope finder](#microscope-finder) instance to interact with it.

Example:

```lua
local close_action = function(microscope)
  microscope:close()
end
```

### Prompt

The `prompt` is a string prefixed to the search query, defaults to "> ".

### Spinner

The `spinner` table represents the specification for the loading spinner, which replaces the input title while retrieving the results. Its structure is as follows:

```lua
local spinner = {
  interval = 500,
  delay = 300,
  position = "center",
  symbols = {
    ".   ",
    " .  ",
    "  . ",
    "   .",
    "  . ",
    " .  ",
  },
}
```

## Builtins

### Lenses

Microscope exposes a list of lens specs in `microscope.builtin.lenses`:

- `cache(...)`: caches results
- `fzf(...)`: filters results using fzf
- `head(limit, ...)`: limits results
- `write(data)`: writes data directly into the flow

### Actions

Microscope exposes a list of actions in `microscope.builtin.actions`:

- `previous`: goes to the previous result
- `next`: goes to the next result
- `scroll_down`: scrolls down preview
- `scroll_up`: scrolls up preview
- `toggle_full_screen`: toggles full screen
- `open`: opens selected results
- `select`: selects result
- `set_layout(layout_fun)`: accepts a [layout function](#layout-function) and returns the corresponding action
- `alter(override_opts)`: accepts a table of options to override in the finder's instance
- `refine`: starts a new search on retrieved results using a fuzzy lens
- `refine_with(lens, parser, prompt)`: starts a new search on retrieved results using a specific lens, parser and optional prompt
- `close`: closes finder

### Parsers

Microscope exposes a list of parsers in `microscope.builtin.parsers`:

- `fuzzy`: highlights result

### Lenses

Microscope exposes a list of layouts in `microscope.builtin.layouts`:

- `default`

## API

### Lens

A lens is used to retrieve or filter data (e.g., a list of files or buffers) depending on the request, and it can be piped into other lenses. It accepts a [lens spec](#lens-spec).

Example:

```lua
local lens = require("microscope.api.lens")

local function rg(cwd)
  return {
    fun = function(flow)
      flow.cmd.shell("rg", { "--files" }, cwd):into(flow)
    end,
  }
end

local function fzf(...)
  return {
    fun = function(flow, request)
      flow.cmd.shell("fzf", { "-f", request.text }):into(flow)
    end,
    inputs = { ... },
  }
end

local my_lens = lens.new(fzf(rg()))
```

#### Lens function

The lens function has two parameters: the [flow](#flow), the [request](#request), and the [context](#context).

##### Flow

The **flow** is a bag of functions:

- `can_read`: returns true if there is at least one input lens.
- `read`: returns `array_string` or `nil` if there is no more input data.
  > `array_string` is a string representing a list of lines separated by a newline and terminating with a newline (e.g., "hello\nworld\n").
- `read_iter`: returns an iterator over `read`.
- `read_array`: returns an array of lines or `nil` if there is no more input data.
- `read_array_iter`: returns an iterator over `read_array`.
- `write`: accepts an `array_string` or a list of lines and propagates the data (e.g., to the next lens).
  > `array_string` is a string representing a list of lines separated by a newline and terminating with a newline (e.g., "hello\nworld\n").
- `stop`: stops the flow.
- `stopped`: returns true if the flow is stopped (e.g., you close the finder before reaching the end of the lens function).
- `cmd`: accessor for [command](#command)
- `fn` (*deprecated*): executes a Vim function passing varargs and returns its result.

  > This is required because one cannot execute Vim functions like `vim.api.nvim_buf_get_name` inside coroutines.

  ```lua
  -- Synthetic way
  local filename = flow.fn(vim.api.nvim_buf_get_name, request.buf)
  -- Verbose way
  local filename = flow.fn(function()
     return vim.api.nvim_buf_get_name(request.buf)
  end)
  ```

- `await` (*deprecated*): executes a function passing varargs and awaits its callback resolution.

  > This is required because one cannot execute Vim functions like `vim.api.nvim_buf_get_name` inside coroutines.

  ```lua
  local data = flow.await(function(resolve, ...)
    an_async_function(function(data)
      resolve(data)
    end)
  end)
  ```

- `command` (*deprecated*): executes a shell command and returns a list of lines.

  ```lua
  local hello_world = flow.command({
    cmd = "echo",
    args = {"hello", "world"}, -- optional
    cwd = nil -- optional
  })
  ```

- `spawn` (*deprecated*): executes a shell command and writes its output into the flow.

  ```lua
  flow.spawn({
    cmd = "echo",
    args = {"hello", "world"}, -- optional
    cwd = nil -- optional
  })
  ```

##### Request

The **request** is an object containing:

- `text`: the searched text
- `buf`: the original bufnr
- `win`: the original winnr

##### Context

The **context** is a table that is shared across multiple requests. It can be used to cache results or to perform logic based on the previous request.

#### Command

The `microscope.api.command` module provides a utility for running commands inside flows.

#### Instantiation

It can be lazy-instantiated with different constructors:

- `shell`: runs a shell command. Args and cwd are optional.

  ```lua
  local mycmd = cmd.shell("echo", { "-n", "hello\nworld" }, cwd)
  ```

- `iter`: consumes an iterator function.

  ```lua
  local elements = { "hello\n", "world\n" }
  local iterator = function()
    return table.remove(elements, 1)
  end

  local mycmd = cmd.iter(iterator)
  ```

- `const`: stores a constant.

  ```lua
  local mycmd = cmd.const("hello\nworld\n")
  -- array version
  local mycmd = cmd.const({ "hello", "world" })
  ```

- `fn`: executes a Vim function passing varargs.

  > This is required because one cannot execute Vim functions like `vim.api.nvim_buf_get_name` inside coroutines.

  ```lua
  -- Synthetic way
  local mycmd = cmd.fn(vim.api.nvim_buf_get_name, request.buf)
  -- Verbose way
  local mycmd = cmd.fn(function()
     return vim.api.nvim_buf_get_name(request.buf)
  end)
  ```

- `await`: executes a function passing varargs, awaiting for the callback resolution.

  > This is required because one cannot execute Vim functions like `vim.api.nvim_buf_get_name` inside coroutines.

  ```lua
  local mycmd = cmd.await(function(resolve, ...)
    an_async_function(function(data)
      resolve(data)
    end)
  end)
  ```

#### Chaining

Once instantiated, it can be chained with other commands:

- `pipe`: pipe to another shell command. Args and cwd are optional.

  ```lua
  local mycmd = cmd
    .shell("echo", { "-n", "hello\nworld" }, cwd)
    :pipe("grep", { "hello" })
  ```

- `filter`: filters using a lua function. The input is a string.

  ```lua
  local mycmd = cmd
    .shell("echo", { "-n", "hello\nworld" }, cwd)
    :filter(function(lines)
      return string.gsub(data, "hello", "hallo")
    end)
  ```

#### Consuming

To consume the command, you can run:

- `collect`: collect the output into an `array_string`.

  ```lua
  local my_echo_result = cmd
    .shell("echo", { "-n", "hello\nworld" }, cwd)
    :collect()
  ```

- `into`: push results into the flow.

  ```lua
  cmd
    .shell("echo", { "-n", "hello\nworld" }, cwd)
    :into(flow)
  ```

### Scope

The `microscope.api.scope` module provides a utility for working with lenses. The `new` function accepts an object with two fields:

- `lens`: a [lens specification](#lens-spec)
- `callback`: an optional callback function that is called at the end

Example:

```lua
local scope = require("microscope.api.scope")

local cat_scope = scope.new({
  lens = {
    fun = function(flow, any_request)
      flow.spawn({
        cmd = "cat",
        args = { any_request.text },
      })
    end,
    callback = function(lines, any_request)
      do_something(lines)
    end,
  },
})

cat_scope:search({
  text = "my_file",
})

-- To stop before completion
cat_scope:stop()
```

This module can be particularly useful when working with the [preview function](#preview-function). You can use it to directly write the obtained lines into the preview window, providing a convenient way to display and interact with the data retrieved by the lens.

### Display

This module provides assistance in building layouts. The functions available for creating displays are as follows:

- `input(size)`: defines the input display. The default size is 1.
- `results(size)`: defines the results display. The default size is nil.
- `preview(size)`: defines the preview display. The default size is nil.
- `space(size)`: defines a fake display to create spacing between and around displays. The default size is nil.
- `vertical(displays, size)`: represents a vertical display. The first parameter is a list of displays, and the second one is the size.
- `horizontal(displays, size)`: represents a horizontal display. The first parameter is a list of displays, and the second one is the size.

The size can be specified in the following ways:

- An integer: represents the number of rows or columns.
- A percentage string (e.g., "40%"): represents the percentage of rows or columns.
- `nil`: indicates that the component will expand to occupy as much space as possible.

To construct the layout, you can use the `build` function of the display instance by passing a size (e.g., finder size).

Example:

```lua
display
  .vertical({
    display.horizontal({
      display.results("40%"),
      display.space(4),
      display.preview(),
    }),
    display.space("10%"),
    display.input(1),
  })
  :build(finder_size)
```

### Microscope Finder

The Microscope Finder instance exposes three components:

- [Input Window](#input-window)
- [Preview Window](#preview-window)
- [Results Window](#results-window)

In addition, the finder provides the following functions:

- `close()`: closes the finder.
- `get_opts()`: retrieves the finder's instance options.
- `set_opts(opts)`: overrides the finder's instance options.
  > This differs from [opts override](#opts-override) since it is only for the instance.
- `alter(lambda)`: overrides the finder's instance options. It accepts a lambda function with one parameter, which is a copy of the finder's instance options. This function should return the new options (`opts`) that will be set. This function effectively combines the functionality of `get_opts` and `set_opts`.

### Input Window

The input window provides the following functions:

- `text()`: returns the text.
- `set_text(text)`: sets the text.
- `reset()`: resets the text.

### Preview Window

The preview window provides the following functions:

- `set_buf_hl(color, line, from, to)`: highlights the buffer.
- `set_win_opt(key, value)`: sets a window option.
- `get_win_opt(key)`: gets a window option.
- `set_buf_opt(key, value)`: sets a buffer option.
- `get_buf_opt(key)`: gets a buffer option.
- `get_win()`: returns the window number of the preview window.
- `get_buf()`: returns the buffer number of the preview window.
- `set_cursor(cursor)`: sets the cursor position safely.
- `get_cursor(cursor)`: retrieves the current cursor position.
- `clear()`: clears the text in the preview window.
- `write(lines, from, to)`: writes lines of text to the buffer of the preview window. The `from` and `to` parameters are optional.
- `write_term(lines)`: writes ANSI lines to the buffer.
- `read(from, to)`: reads lines from the buffer of the preview window.

### Results Window

The results window provides the following functions:

- `set_buf_hl(color, line, from, to)`: highlights the buffer.
- `set_win_opt(key, value)`: sets a window option.
- `set_buf_opt(key, value)`: sets a buffer option.
- `get_win()`: returns the window number of the results window.
- `get_buf()`: returns the buffer number of the results window.
- `set_cursor(cursor)`: sets the cursor position safely.
- `get_cursor(cursor)`: retrieves the current cursor position.
- `clear()`: clears the text in the results window.
- `write(lines, from, to)`: writes lines of text to the buffer of the results window. The `from` and `to` parameters are optional.
- `read(from, to)`: reads lines from the buffer of the results window.
- `raw_results()`: returns the list of retrieved and unparsed results.
- `select()`: adds the focused result to the selected results.
- `selected()`: obtains the list of selected results.
- `open(metadata)`: opens the selected results. The `metadata` parameter can be any data you want to pass to the `open` function.

### Highlight

The `microscope.api.highlight` module allows you to create highlights for a line.

Example:

```lua
local highlight = require("microscope.api.highlight")

local data = {
  text = "1: buffer one",
  highlights = {},
}
local highlights = highlight
  .new(data.highlights, data.text)
  :hl_match(highlight.color.color1, "(%d+:)(.*)", 1) -- highlight the first group with color1
  :hl(highlight.color.color2, 3, 10) -- highlight from column 3 to 10 with color2
  :get_highlights()
```

Another utility function is `microscope.utils.highlight`. This function accepts a `path` and a `bufnr` and automatically highlights the buffer based on the inferred filetype.

### Error

The `microscope.api.error` module allows you to display an error. It provides two useful functions:

- `generic(message)`: displays a generic error message.
- `critical(message)`: displays an error message and closes the finder.

## Plugins

Plugins can expose finders, lens specs, actions, parsers, previews, and open functions. This allows you to use pre-packaged finders or easily create custom finders using the provided building blocks. Here's an example:

```lua
local microscope = require("microscope")
local lenses = require("microscope.builtin.lenses")
local parsers = require("microscope.builtin.parsers")

local files = require("microscope-files")

local function ls()
  return {
    fun = function(flow)
      flow.cmd.shell("ls")
    end,
  }
end

microscope.setup({ ... })

microscope.register(files.finders)
microscope.register({
  ls = {
    lens = lenses.fzf(ls()),
    preview = files.preview.cat,
    parsers = { files.parsers.file, parsers.fuzzy },
  },
})
```

You can also explore the already published plugins:

- [microscope-buffers](https://github.com/danielefongo/microscope-buffers)
- [microscope-code](https://github.com/danielefongo/microscope-code)
- [microscope-files](https://github.com/danielefongo/microscope-files)
- [microscope-git](https://github.com/danielefongo/microscope-git)

## Testing

- Clone [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) in root folder.
- Install luacov

  ```bash
  luarocks install luacov
  luarocks install luacov-console
  luarocks install luacov-html
  ```

- Run tests

  ```bash
  # without coverage
  make test [test=path-to-file]
  # with coverage
  make testcov
  # with coverage + html report
  make testcov-html
  ```
