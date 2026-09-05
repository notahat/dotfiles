-- Configure language server integration.
return {
  "neovim/nvim-lspconfig",
  config = function()
    vim.lsp.enable({ "bashls", "lua_ls", "eslint", "ts_ls" })

    -- Sorbet is only installed on work machines.
    if vim.fn.executable("srb") == 1 then
      vim.lsp.enable({ "sorbet" })
      -- relay_lsp is missing, see https://github.com/neovim/nvim-lspconfig/issues/3705
    end
  end,
}
