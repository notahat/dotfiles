local opts = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    -- Handle both completion and snippets when hitting tab.
    local function tab(fallback)
        if cmp.visible() then
            cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
        else
            fallback()
        end
    end

    local function shift_tab(fallback)
        if cmp.visible() then
            cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
        else
            fallback()
        end
    end

    return {
        sources = {
            { name = "nvim_lsp", group_index = 1 },
            { name = "luasnip", group_index = 1 },
            { name = "buffer", group_index = 2 },
        },
        mapping = cmp.mapping.preset.insert({
            ["<Tab>"] = cmp.mapping(tab, { "i", "s" }),
            ["<S-Tab"] = cmp.mapping(shift_tab, { "i", "s" }),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        snippet = {
            expand = function(args)
                require("luasnip").lsp_expand(args.body)
            end,
        },
    }
end

return {
    "hrsh7th/nvim-cmp",
    dependencies = {
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
    },
    opts = opts,
}
