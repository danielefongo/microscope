# Microscope

Micro fuzzy finder for neovim

## Disclaimer

The project is full of bugs and still in development (until I abandon the project, as always :D)

## Configuration

On lazy.vim

```lua
{
  "danielefongo/microscope",
  config = function()
    local actions = require("microscope.actions")

    local lists = require("microscope.lists")
    local files = require("microscope.files")

    local view = require("microscope").setup({
      size = {
        width = 50,
        height = 10,
      },
      bindings = {
        ["<c-j>"] = actions.next,
        ["<c-k>"] = actions.previous,
        ["<a-j>"] = actions.scroll_down,
        ["<a-k>"] = actions.scroll_up,
        ["<tab>"] = actions.open,
        ["<esc>"] = actions.close,
        ["<tab>"] = actions.select,
      },
    })

    vim.keymap.set(
      "n",
      "<leader>of",
      view:finder({
        chain = function(text)
          return { files.lists.rg(), lists.fzf(text), lists.head(10) }
        end,
        open = files.open,
        preview = files.preview,
      })
    )
  end,
}
```
