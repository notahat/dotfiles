-- Fancy snippets completion
--
-- https://github.com/L3MON4D3/LuaSnip

local function config()
    local luasnip = require("luasnip")
    luasnip.filetype_extend("ruby", { "rails" })

    -- This loads the snippets from friendly-snippets.
    require("luasnip.loaders.from_vscode").lazy_load()
end

return {
    "L3MON4D3/LuaSnip",
    build = "make install_jsregexp",
    config = config,
    dependencies = { "rafamadriz/friendly-snippets" },
    lazy = true, -- This'll get loaded by nvim-cmp.
}
