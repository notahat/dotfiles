-- Make the status line look clean and pretty.

local function copy_relative_path()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  vim.notify("Path copied: " .. path)
end

local function lsp_progress()
  return require("lsp-progress").progress()
end

local function open_diagnostics()
  require("trouble").open("diagnostics")
end

local function show_lsp_info()
  vim.cmd("checkhealth vim.lsp")
end

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    extensions = { "lazy", "man", "mason", "oil", "quickfix" },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { { "diagnostics", on_click = open_diagnostics } },
      lualine_c = {
        { "filename", on_click = copy_relative_path, path = 1, shorting_target = 20 },
      },
      lualine_x = {
        { lsp_progress, on_click = show_lsp_info },
      },
      lualine_y = {},
      lualine_z = { "%p%%/%L" },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {
        { "filename", on_click = copy_relative_path, path = 1, shorting_target = 20 },
      },
      lualine_x = {},
      lualine_y = {},
      lualine_z = {},
    },
  },
}
