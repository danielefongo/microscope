# Microscope

Micro fuzzy finder for neovim.

## Disclaimer

The project is full of bugs and still in development (until I abandon the project, as always :D)

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
    local actions = require("microscope.actions")

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
    vim.keymap.set("n", "<leader>of", microscope.finders.file:bind())
    vim.keymap.set("n", "<leader>oo", microscope.finders.old_file:bind())
  end,
}
```

You can create your own [finder](#finder).

## Finder

Every finder can be defined using the following opts:

```lua
local opts = {
  chain = chain_fn, -- required
  open = open_fn, -- optional
  preview = preview_fn, -- optional
  size = custom_size, -- optional, it will override/extend the microscope size option
  bindings = custom_bindings, -- optional, it will override/extend the microscope bindings option
}
```

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

### Chain function

This function represents the heart of the plugin. It accepts the prompt text, the original winnr and bufnr and returns a list of [chain-steps](#chain-step). It uses [stream](#stream) under the hood.

Example:

```lua
local chain_fn = function(text, winnr, bufnr)
  return {
    { command = "ls" },
    { command = "grep", args = { text } },
  }
end
```

#### Chain step

A single chain-step can be either a shell command or a lua function and can be concatenated with other chain-steps to build a pipeline.

##### Chain step command

```lua
local chain_step = {
    command = "ls",
    args = { "." }, -- optional
    parser = parser_fn, -- optional
}
```

##### Chain step function

This spec changes depending on whether it is a downstream chain-step or the first chain-step in the chain.

The former can be defined like

```lua
local chain_step = {
  fun = function(on_data_callback)
    local data = { "first", "second" }
    on_data_callback(data)
  end,
  parser = parser_fn, -- optional
}
```

The latter can be defined like

```lua
local chain_step = {
  filter = function(text)
    return text .. " additional text"
  end,
  parser = parser_fn, -- optional
}
```

##### Parser function

This optional chain-step function accepts result data and transforms it by adding extra information. The first chain-step will receive a data containing only the `text` field. Each parser function must propagate this field, even if modified, as it will be used to render the result. The extra information can be something like `file` or whatever you want to add. The final data table will be passed to the [open function](#open-function) and to the [preview function](#preview-function).

There is another special data field, `highlights`, which should be propagated unless you want to remove it. It represents a list of highlights to be applied to the result. For more details see the [highlight section](#highlight).

Example:

```lua
local parser_fn = function(data)
  local elements = vim.split(data.text, ":", {})

  return {
    text = data.text,
    highlights = build_highlights(data),
    buffer = tonumber(elements[1]),
  }
end
```

### Open function

This function will be called with the `open` action. It accepts a single result data obtained from the chain, the original winnr and bufnr and optional metadata (sent by results:open).

Example:

```lua
local open_fn = function(data, winnr, bufnr, metadata)
  vim.cmd("e " .. data.file)
end
```

### Preview function

This function will be called whenever a result is focused. It accepts a single result data obtained from the chain and the `preview` microscope instance.

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
local actions = require("microscope.actions")

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

## API

### Stream

The module `microscope.stream` is a utility for building chains. It can be used to execute a pipeline and to perform an action with the obtained lines.

Example:

```lua
local stream = require("microscope.stream")

local cat_stream = stream.chain({
  { command = "cat", args = { "myfile" } },
}, function(lines)
  do_smth(lines)
end)

cat_stream:start()

-- to stop before completion
cat_stream:stop()
```

This function can be useful, for example, on [preview function](#preview-function): you can write the lines obtained directly in the preview window.

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
- `open(medatada)`: open the selected results. `metadata` can be anything you want to pass to `open` function.

### Highlight

The module `microscope.highlight` can be used to build highlights for a line.

Example

```lua
local highlight = require("microscope.highlight")
local constants = require("microscope.constants")

local data = {
  text = "1: buffer one",
  highlights = {},
}
local highlights = highlight
  .new(data.highlights, data.text)
  :hl_match(constants.color.color1, "(%d+:)(.*)", 1) -- highlight first group
  :hl(constants.color.color2, 3, 10) -- highlight from col 3 to 10
  :get_highlights()
```

Another utility function can be found in `microscope.utils.highlight`. This function accepts a `path` and a `bufnr` and highlights the buffer by inferring the filetype.

### Error

The module `microscope.error` can be used to display an error. It exposes two useful functions:

- `generic(message)`: it shows the error message
- `critical(message)`: it shows the error message and close finder

## Plugins

A plugin can expose finders, actions, steps, preview functions and open functions. In this way, it is possible to have pre-packaged finders or to easily create custom finders by using the provided building blocks.

Example:

```lua
local microscope = require("microscope")
local steps = require("microscope.steps")

local files = require("microscope-files")

local ls_step = {
  command = "ls",
  parser = function(data)
    return {
      text = data.text,
      file = data.text,
    }
  end,
}

microscope.register(files.finders)
microscope.register({
  ls = {
    preview = files.preview.cat,
    chain = function(text)
      return { ls_step, steps.fzf(text) }
    end,
  },
})
```

Take a look to already published plugins:

- [microscope-buffers](https://github.com/danielefongo/microscope-buffers)
- [microscope-code](https://github.com/danielefongo/microscope-code)
- [microscope-files](https://github.com/danielefongo/microscope-files)
- [microscope-git](https://github.com/danielefongo/microscope-git)
