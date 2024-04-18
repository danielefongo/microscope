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

local function load_opts(finder_args_raw)
  if finder_args_raw == "" then
    finder_args_raw = "{}"
  end
  local func, err = load("return " .. finder_args_raw, "table_string", "t")

  if err or not func then
    error("microscope: malformed opts: " .. vim.inspect(finder_args_raw))
    return
  end

  local ok, opts = pcall(func)

  if not ok then
    error("microscope: malformed opts: " .. vim.inspect(finder_args_raw))
  end

  return opts
end

vim.api.nvim_create_user_command("Microscope", function(opts)
  local finder_name, finder_args_raw = opts.args:match("(%S+)%s*(.*)")

  require("microscope").finders[finder_name](load_opts(finder_args_raw))
end, {
  nargs = "?",
  complete = function(_, line)
    return vim.tbl_filter(function(val)
      return vim.startswith(val, line:gsub("Microscope ", ""))
    end, vim.tbl_keys(require("microscope").finders))
  end,
})
