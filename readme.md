# Microscope

Micro fuzzy finder for neovim

## Disclaimer

The project is full of bugs and still in development (until I abandon the project, as always :D)

## Configuration

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
    vim.keymap.set("n", "<leader>of", microscope.finders.file)
    vim.keymap.set("n", "<leader>oo", microscope.finders.old_file)
  end,
}
```

You can create your own finder

```lua
local files = require("microscope-files")
local buffers = require("microscope-buffers")
local steps = require("microscope.steps")

microscope.register({
  files = {
    chain = function(text)
      return { files.steps.rg(), steps.fzf(text), steps.head(10) }
    end,
    open = files.open,
    preview = files.preview.cat,
  },
  second_finder = { ... },
})
```
