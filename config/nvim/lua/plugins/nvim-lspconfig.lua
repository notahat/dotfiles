-- Configure language server integration.
return {
  "neovim/nvim-lspconfig",
  config = function()
    vim.lsp.enable({ "bashls", "ts_ls", "lua_ls" })
    -- eslint is missing, see https://github.com/neovim/nvim-lspconfig/issues/3705

    if os.getenv("DOTFILES_ENV") == "work" then
      vim.lsp.enable({ "sorbet" })
      -- relay_lsp is also missing
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
