# YAFF

Yet Another Fuzzy Finder for neovim

## Disclaimer

The project is full of bugs and still in development (until I abandon the project, as always :D)

## Configuration

On lazy.vim

```lua
{
  "danielefongo/yaff",
  config = function()
    local actions = require("yaff.actions")
    local lists = require("yaff.lists")
    local open = require("yaff.open")

    local view = require("yaff").setup({
      size = {
        width = 50,
        height = 10,
      },
      bindings = {
        ["<c-j>"] = actions.next,
        ["<c-k>"] = actions.previous,
        ["<tab>"] = actions.open,
        ["<esc"] = actions.close,
      },
    })

    vim.keymap.set(
      "n",
      "<leader>of",
      view:finder({
        chain = function(text)
          return { lists.rg(), lists.fzf(text), lists.head(10) }
        end,
        open = open.file,
      })
    )
  end,
}
```
