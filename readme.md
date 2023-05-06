# Microscope

Micro fuzzy finder for neovim.

## Disclaimer

The project is still in development, so expect the API to change.

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

    local files = require("microscope-files")
    local buffers = require("microscope-buffers")

    microscope.setup({
      size = {
        width = 80,
        height = 30,
      },
      bindings = {
        ["<c-j>"] = actions.next,
        ["<c-k>"] = actions.previous,
        ["<a-j>"] = actions.scroll_down,
        ["<a-k>"] = actions.scroll_up,
        ["<cr>"] = actions.open,
        ["<esc>"] = actions.close,
        ["<tab>"] = actions.select,
        ["<c-f>"] = actions.toggle_full_screen,
      },
    })

    microscope.register(files.finders)
    microscope.register(buffers.finders)

    -- bind using microscope instance
    vim.keymap.set("n", "<leader>of", microscope.finders.file:bind())
    vim.keymap.set("n", "<leader>oo", microscope.finders.old_file:bind())

    -- bind using microscope commands
    vim.keymap.set("n", "<leader>of", ":Microscope file<cr>")
    vim.keymap.set("n", "<leader>oo", ":Microscope old_file<cr>")
  end,
}
```

You can create your own [finder](#finder).

## Finder

Every finder can be defined using the following opts:

```lua
local opts = {
  lens = lens_spec, -- required
  parsers = list_of_parsers -- optional
  open = open_fn, -- optional
  preview = preview_fn, -- optional
  size = custom_size, -- optional, it will override/extend the microscope size option
  bindings = custom_bindings, -- optional, it will override/extend the microscope bindings option
}
```

These properties are defined below.

#### Creation

A finder can be created in one of two ways:

```lua
local microscope = require("microscope")

-- first way
local finder = microscope.finder(opts)

-- second way (it will register finder as microscope.finders.name)
local finder = microscope.register({
  name = opts
})
```

#### Binding

After its creation, the finder can be invoked as a function, so it is enough to bind it to a shortcut:

```lua
-- first way
vim.keymap.set("n", "<leader>of", finder)

-- second way
vim.keymap.set("n", "<leader>of", microscope.finders.name)
```

#### Opts override

After the finder creation, it is possible to override its opts.

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

This element represents a spec for a [lens](#lens), which is used to retrieve or filter data (e.g. list of files or buffers) depending on the [request](#request). It is a table containing a [lens function](#lens-function) and a list of input lenses specs.

```lua
local lens = {
  fun = function(flow, request, context)
    -- logic
  end,
  inputs = { ... }, -- list of other lens specs, optional
}
```

Example:

```lua
local lenses = {}

function lenses.rg(cwd)
  return {
    fun = function(flow)
      flow.spawn({
        cmd = "rg",
        args = { "--files" },
        cwd = cwd,
      })
    end,
  }
end

function lenses.fzf(...)
  return {
    fun = function(flow, request)
      flow.spawn({
        cmd = "fzf",
        args = { "-f", request.text },
      })
    end,
    inputs = { ... },
  }
end

local my_lens = lenses.fzf(lenses.rg())
```

### Parsers

This is a list of [parser functions](#parser-function) to parse the data retrieved from the [lens](#lens).

#### Parser function

This function accepts result data and the original [request](#request) and transforms the data by adding extra information. The first parser will receive a data containing only the `text` field. Each parser function must propagate this field, even if unmodified, as it will be used to render the result. The extra information can be something like `file` or whatever you want to add. The final data table will be passed to the [open function](#open-function) and to the [preview function](#preview-function).

There is another special data field, `highlights`, which should be propagated unless you want to remove it. It represents a list of highlights to be applied to the result. For more details see the [highlight section](#highlight).

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

This function will be called with the [open action](#actions). It accepts a single result data obtained from the parsers, the [request](#request) and optional metadata (sent by `results:open`).

Example:

```lua
local open_fn = function(data, request, metadata)
  vim.cmd("e " .. data.file)
end
```

### Preview function

This function will be called whenever a result is focused. It accepts a single result data obtained from the parsers and the `preview` microscope instance.

Example:

```lua
local preview_fn = function(data, window)
  window:write({ data.text })
end
```

More details about preview window api can be found in [its section](#preview-window).

### Size

Size is a lua table containing a `width` and an `height`.

### Bindings

This table contains shortcut bindings to microscope [actions](#action).

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

## Builtins

### Lenses

Microscope exposes a list of lens specs in `microscope.builtin.lenses`:

- `cache(...)`: cache results
- `fzf(...)`: filter results using fzf
- `head(lines, ...)`: limit results

### Actions

Microscope exposes a list of actions in `microscope.builtin.actions`:

- `previous`: go to the previous result
- `next`: go to the next result
- `scroll_down`: scroll down preview
- `scroll_up`: scroll up preview
- `toggle_full_screen`: toggle full screen
- `open`: open selected results
- `select`: select result
- `close`: close finder

### Parsers

Microscope exposes a list of parsers in `microscope.builtin.parsers`:

- `fuzzy`: highlights result

## API

### Lens

A lens is used to retrieve or filter data (e.g. list of files or buffers) depending on the request and it can be piped into other lenses. It accepts a [lens spec](#lens-spec).

Example:

```lua
local lens = require("microscope.api.lens")

local function rg(cwd)
  return {
    fun = function(flow)
      flow.spawn({
        cmd = "rg",
        args = { "--files" },
        cwd = cwd,
      })
    end,
  }
end

local function fzf(...)
  return {
    fun = function(flow, request)
      flow.spawn({
        cmd = "fzf",
        args = { "-f", request.text },
      })
    end,
    inputs = { ... },
  }
end

local my_lens = lens.new(fzf(rg()))
```

#### Lens function

The lens function has two parameters, the [flow](#flow), the [request](#request) and the [context](#context).

##### Flow

The **flow** is a bag of functions:

- `can_read`: returns true if there is at least one input lens.
- `read`: returns [array_string](#array-string) or `nil` if there is no more input data.
  > `array_string` is a string representing a list of lines separated by newline and terminating with a newline (e.g. _"hello\nworld\n"_).
- `read_iter`: returns an iterator over `read`.
- `read_array`: returns an array of lines or `nil` if there is no more input data.
- `read_array_iter`: returns an iterator over `read_array`.
- `write`: it accepts an [array_string](#array-string) or a list of lines and propagate the data (e.g. to the next lens).
  > `array_string` is a string representing a list of lines separated by newline and terminating with a newline (e.g. _"hello\nworld\n"_).
- `stop`: stop the flow.
- `stopped`: returns true if the flow is stopped (e.g. you close the finder before reaching the end of the lens function).
- `fn`: executes a vim function passing varargs and returns its result.

  > This is required because one cannot execute vim functions like `vim.api.nvim_buf_get_name` inside corutines.

  ```lua
  -- synthetic way
  local filename = flow.fn(vim.api.nvim_buf_get_name, request.buf)

  -- verbose way
  local filename = flow.fn(function()
     return vim.api.nvim_buf_get_name(request.buf)
  end)
  ```

- `await`: executes a function passing varargs and awaits for its callback resolution.

  > This is required because one cannot execute vim functions like `vim.api.nvim_buf_get_name` inside corutines.

  ```lua
  local data = flow.await(function(resolve, ...)
    an_async_function(function(data)
      resolve(data)
    end)
  end)
  ```

- `command`: executes a shell command and returns a list of lines.

  ```lua
  local hello_world = flow.command({
    cmd = "echo",
    args = {"hello", "world"}, -- optional
    cwd = nil -- optional
  })
  ```

- `spawn`: executes a shell command and writes its output in the flow.

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

The **context** is a table that is shared across multiple requests. It can be used to cache results or to do logic depending on the previous request.

### Scope

The module `microscope.api.scope` is a utility for using a lens. The `new` function accepts an object with 3 fields:

- [lens](#lens-spec): a lens spec
- `callback`: this is called at the end (optional).
- [parser](#parser-function): this is applied to every result before the `callback` invocation.

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
      do_smth(lines)
    end,
  },
})

cat_scope:search({
  text = "my_file",
})

-- to stop before completion
cat_scope:stop()
```

This module can be useful, for example, on [preview function](#preview-function): you can write the lines obtained directly in the preview window.

### Microscope finder

Microscope's finder instance exposes 3 components:

- [preview window](#preview-window)
- [results window](#results-window)
- input window (not really useful)

In addition, finder exposes the following functions:

- `close()`: close the finder
- `toggle_full_screen()`: toggle full screen

### Preview window

Preview window exposes the following functions:

- `set_buf_hl(color, line, from, to)`: highlight buffer
- `set_win_opt(key, value)`: set window option
- `set_buf_opt(key, value)`: set buffer option
- `get_win()`: return the handled winnr
- `get_buf()`: return the handled bufnr
- `set_buf(buf)`: set alternative bufnr
- `set_cursor(cursor)`: set cursor safely
- `get_cursor(cursor)`: get the current cursor
- `clear()`: clear text
- `write(lines, from, to)`: write lines to buffer (from and to are optionals)
- `write_term(lines)`: write ansi lines
- `read(from, to)`: read lines from buffer

### Results window

Preview window exposes the following functions:

- `set_buf_hl(color, line, from, to)`: highlight buffer
- `set_win_opt(key, value)`: set window option
- `set_buf_opt(key, value)`: set buffer option
- `get_win()`: return the handled winnr
- `get_buf()`: return the handled bufnr
- `set_buf(buf)`: set alternative bufnr
- `set_cursor(cursor)`: set cursor safely
- `get_cursor(cursor)`: get the current cursor
- `clear()`: clear text
- `write(lines, from, to)`: write lines to buffer (from and to are optionals)
- `read(from, to)`: read lines from buffer
- `select()`: add focused result to selected results
- `selected()`: obtain list of results
- `open(medatada)`: open the selected results. `metadata` can be anything you want to pass to `open` function

### Highlight

The module `microscope.api.highlight` can be used to build highlights for a line.

Example

```lua
local highlight = require("microscope.api.highlight")

local data = {
  text = "1: buffer one",
  highlights = {},
}
local highlights = highlight
  .new(data.highlights, data.text)
  :hl_match(highlight.color.color1, "(%d+:)(.*)", 1) -- highlight first group with color1
  :hl(highlight.color.color2, 3, 10) -- highlight from col 3 to 10 with color2
  :get_highlights()
```

Another utility function is `microscope.utils.highlight`. This function accepts a `path` and a `bufnr` and highlights the buffer by inferring the filetype.

### Error

The module `microscope.api.error` can be used to display an error. It exposes two useful functions:

- `generic(message)`: it shows the error message
- `critical(message)`: it shows the error message and close the finder

## Plugins

A plugin can expose finders, lenses specs, actions, parsers, previews and open functions. This way, it is possible to have pre-packaged finders or to easily create custom finders by using the provided building blocks.

Example:

```lua
local microscope = require("microscope")
local lenses = require("microscope.builtin.lenses")
local parsers = require("microscope.builtin.parsers")

local files = require("microscope-files")

local function ls()
  return {
    fun = function(flow)
      flow.command({ cmd = "ls" })
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

Take a look to already published plugins:

- [microscope-buffers](https://github.com/danielefongo/microscope-buffers)
- [microscope-code](https://github.com/danielefongo/microscope-code)
- [microscope-files](https://github.com/danielefongo/microscope-files)
- [microscope-git](https://github.com/danielefongo/microscope-git)
