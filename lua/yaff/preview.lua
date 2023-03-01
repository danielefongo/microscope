local stream = require("yaff.stream")
local lists = require("yaff.lists")

local preview = {}

local function highlight_buf(path, buf)
  vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. "/" .. path)
  vim.api.nvim_buf_call(buf, function()
    local eventignore = vim.api.nvim_get_option("eventignore")
    vim.api.nvim_set_option("eventignore", "FileType")
    vim.api.nvim_command("filetype detect")
    return vim.api.nvim_set_option("eventignore", eventignore)
  end)
  local ft = vim.api.nvim_buf_get_option(buf, "filetype")

  if not ft or ft == "" then
    return
  end

  if pcall(require, "nvim-treesitter") then
    local highlight = require("nvim-treesitter.highlight")
    local parsers = require("nvim-treesitter.parsers")

    local lang = parsers.ft_to_lang(ft)
    if parsers.has_parser(lang) then
      return highlight.attach(buf, lang)
    end
  end

  return vim.api.nvim_buf_set_option(buf, "syntax", ft)
end

function preview.buffer(data, win, _)
  vim.schedule(function()
    vim.api.nvim_win_set_buf(win, data.buffer)
  end)
end

function preview.file(data, win, buf)
  local cursor
  if data.col and data.row then
    cursor = { data.row, data.col }
  else
    cursor = { 1, 0 }
  end
  stream
    .chain({
      lists.cat(data.text),
      lists.head(5000),
    }, function(lines)
      vim.schedule(function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
        highlight_buf(data.text, buf)
        vim.api.nvim_win_set_cursor(win, cursor)
      end)
    end)
    :start()
end

return preview
