-- Make editing my neovim config files much nicer.

local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- See https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#lua_ls
local lua_settings = {
    Lua = {
        runtime = {
            version = "LuaJIT",
        },
        workspace = {
            checkThirdParty = false,
            library = {
                vim.env.VIMRUNTIME,
            },
        },
    },
}

lspconfig.lua_ls.setup({
    capabilities = capabilities,
    settings = lua_settings,
})