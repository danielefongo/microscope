if vim.g.loaded_microscope == 1 then
  return
end
vim.g.loaded_microscope = 1

local highlights = {
  MicroscopeMatch = { default = true, fg = "cyan" },
  MicroscopeColor1 = { default = true, fg = "red" },
  MicroscopeColor2 = { default = true, fg = "green" },
  MicroscopeColor3 = { default = true, fg = "yellow" },
  MicroscopeColor4 = { default = true, fg = "blue" },
  MicroscopeColor5 = { default = true, fg = "magenta" },
  MicroscopeColor6 = { default = true, fg = "cyan" },
}

for k, v in pairs(highlights) do
  vim.api.nvim_set_hl(0, k, v)
end

vim.api.nvim_create_user_command("Microscope", function(opts)
  require("microscope").finders[opts.args]()
end, {
  nargs = 1,
  complete = function(_, line)
    return vim.tbl_filter(function(val)
      return vim.startswith(val, line:gsub("Microscope ", ""))
    end, vim.tbl_keys(require("microscope").finders))
  end,
})
