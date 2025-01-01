-- Auto-format files.
--
-- This hooks non-LSP formatters into Neovim's LSP system.
--
-- It's a fork of null-ls, hence the requires for null-ls rather than none-ls.
return {
  "nvimtools/none-ls.nvim",
  config = function()
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.prettierd,
        null_ls.builtins.formatting.stylua,
      },
    })
  end,
}
