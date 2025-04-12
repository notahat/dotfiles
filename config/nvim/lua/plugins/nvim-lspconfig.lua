-- Configure language server integration.
return {
  "neovim/nvim-lspconfig",
  config = function()
    local lspconfig = require("lspconfig")
    local capabilities = require("blink.cmp").get_lsp_capabilities()

    lspconfig.bashls.setup({ capabilities = capabilities })
    lspconfig.eslint.setup({ capabilities = capabilities })
    lspconfig.ts_ls.setup({ capabilities = capabilities })

    if os.getenv("DOTFILES_ENV") == "work" then
      lspconfig.relay_lsp.setup({ capabilities = capabilities })
      lspconfig.sorbet.setup({ capabilities = capabilities })
    end

    lspconfig.lua_ls.setup({
      capabilities = capabilities,
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
