-- Make the status line look clean and pretty.

local function copy_relative_path()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  vim.notify("Path copied: " .. path)
end

local function has_noice_mode()
  require("noice").api.status.mode.has()
end

local function noice_mode()
  require("noice").api.status.mode.get()
end

local function lsp_progess()
  return require("lsp-progress").progress()
end

local function show_lsp_info()
  vim.cmd("checkhealth lspconfig")
end

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    extensions = { "lazy", "man", "mason", "oil", "quickfix" },
    options = { globalstatus = true },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "diagnostics" },
      lualine_c = { { "filename", on_click = copy_relative_path, path = 1, shorting_target = 20 } },
      lualine_x = {
        -- Show macro recording messages.
        {
          noice_mode,
          cond = has_noice_mode,
          color = { fg = "#ff9e64" },
        },
        { lsp_progess, on_click = show_lsp_info },
      },
      lualine_y = { "searchcount" },
      lualine_z = { "%p%%/%L" },
    },
  },
}
