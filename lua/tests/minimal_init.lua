if os.getenv("TEST_COV") then
  require("luacov")
end

vim.opt.rtp:append(".")
vim.opt.rtp:append("plenary.nvim")
