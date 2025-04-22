-- Configure language server integration.
return {
  "neovim/nvim-lspconfig",
  config = function()
    vim.lsp.enable({ "bashls", "lua_ls", "eslint", "ts_ls" })

    if os.getenv("DOTFILES_ENV") == "work" then
      vim.lsp.enable({ "sorbet" })
      -- relay_lsp is missing, see https://github.com/neovim/nvim-lspconfig/issues/3705
    end

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          workspace = {
            checkThirdParty = false,
            library = { vim.env.VIMRUNTIME, "${3rd}/luv/library" },
          },
        },
      },
    })
  end,
}
