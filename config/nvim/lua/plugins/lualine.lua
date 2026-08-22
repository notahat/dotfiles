-- Make the status line look clean and pretty.

local function copy_relative_path()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  vim.notify("Path copied: " .. path)
end

local function open_diagnostics()
  require("fzf-lua").diagnostics_workspace()
end

local function show_lsp_info()
  vim.cmd("checkhealth vim.lsp")
end

-- Neovim reports language server progress through the LspProgress event, but
-- leaves the formatting to us. Note that vim.ui.progress_status() is no help
-- here: it only tracks progress messages made with nvim_echo, which the
-- language server client doesn't use.
local latest_progress = ""

local function format_progress(value)
  if type(value) ~= "table" or value.kind == "end" then
    return ""
  end
  if value.percentage then
    -- The doubled %% is what the status line needs to render one.
    return string.format("%s %d%%%%", value.title or "", value.percentage)
  end
  return value.title or ""
end

-- Nudge lualine as well as recording the message, so progress doesn't wait for
-- the once-a-second refresh timer.
local function track_lsp_progress(event)
  latest_progress = format_progress(event.data.params.value)
  require("lualine").refresh({ place = { "statusline" } })
end

local function lsp_progress()
  return latest_progress
end

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function(_, opts)
    require("lualine").setup(opts)
    vim.api.nvim_create_autocmd("LspProgress", { callback = track_lsp_progress })
  end,
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
