return function(path, buf)
  local ft = vim.filetype.match({ filename = path })

  if pcall(require, "nvim-treesitter") then
    local highlight = require("nvim-treesitter.highlight")
    local parsers = require("nvim-treesitter.parsers")

    highlight.detach(buf)
    if not ft or ft == "" then
      return
    end

    local lang = parsers.ft_to_lang(ft)
    if parsers.has_parser(lang) then
      return highlight.attach(buf, lang)
    end
  end

  return vim.api.nvim_buf_set_option(buf, "syntax", ft)
end
