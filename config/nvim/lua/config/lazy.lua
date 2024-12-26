-- Install lazy.nvim, and load all the plugins.

-- This file is taken straight from the lazy.nvim installation instructions:
-- https://lazy.folke.io/installation
--
-- See Best Practices in the docs for how to write good plugin specs:
-- https://lazy.folke.io/developers#best-practices

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  spec = { import = "plugins" },
  install = { colorscheme = { "nordfox" } },
  checker = { enabled = true },
  rocks = { enabled = false },
})
