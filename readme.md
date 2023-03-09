# Microscope

Micro fuzzy finder for neovim

## Disclaimer

The project is full of bugs and still in development (until I abandon the project, as always :D)

## Configuration

On [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "danielefongo/microscope",
  config = function()
    local microscope = require("microscope")
    local actions = require("microscope.actions")

    local lists = require("microscope.lists")
    local files = require("microscope.files")

    microscope.setup({
      size = {
        width = 50,
        height = 10,
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

    -- binding mode 1
    local files_finder = microscope.finder({
      chain = function(text)
        return { files.lists.rg(), lists.fzf(text), lists.head(10) }
      end,
      open = files.open,
      preview = files.preview,
    })
    vim.keymap.set("n", "<leader>of", files_finder)

    -- binding mode 2
    microscope.register({
      files = {
        chain = function(text)
          return { files.lists.rg(), lists.fzf(text), lists.head(10) }
        end,
        open = files.open,
        preview = files.preview,
      },
      second_finder = { ... }
    })
    microscope.register({
      third_finder = { ... }
    })
    vim.keymap.set("n", "<leader>of", microscope.finders.files)
    vim.keymap.set("n", "<leader>o2", microscope.finders.second_finder)
    vim.keymap.set("n", "<leader>o3", microscope.finders.third_finder)
  end,
}
```
