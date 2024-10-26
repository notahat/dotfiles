local function copy_relative_path()
    local path = vim.fn.expand("%:.")
    vim.fn.setreg("+", path)
    vim.notify("Path copied: " .. path)
end

local function lsp_progess()
    return require("lsp-progress").progress()
end

local function show_lsp_info()
    vim.cmd("checkhealth lspconfig")
end

return {
    extensions = { "lazy", "man", "mason", "quickfix" },
    options = { globalstatus = true },
    -- options = { disabled_filetypes = { "neo-tree" } },
    sections = {
        lualine_a = { "mode" },
        lualine_b = { "diagnostics" },
        lualine_c = { { "filename", on_click = copy_relative_path, path = 1, shorting_target = 20 } },
        lualine_x = { { lsp_progess, on_click = show_lsp_info } },
        lualine_y = { "searchcount" },
        lualine_z = { "%p%%/%L" },
    },
    -- This stuff doesn't matter with globalstatus enabled:
    -- inactive_sections = {
    --     lualine_a = {},
    --     lualine_b = {},
    --     lualine_c = { { "filename", path = 1, shorting_target = 0 } },
    --     lualine_x = {},
    --     lualine_y = {},
    --     lualine_z = {},
    -- },
}
