return function(path, buf)
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
