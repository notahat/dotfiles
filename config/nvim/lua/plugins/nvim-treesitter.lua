-- Provide syntax highlighting and textobjects through the treesitter parser.

-- Neovim only starts treesitter for a handful of filetypes itself, and
-- nvim-treesitter installs parsers without enabling highlighting. The pcall
-- swallows the error for filetypes with no parser installed.
local function start_treesitter(event)
  pcall(vim.treesitter.start, event.buf)
end

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  config = function()
    -- Neovim bundles the c, lua, markdown, markdown_inline, query, vim, and
    -- vimdoc parsers, so they're left out here.
    require("nvim-treesitter").install({
      "bash",
      "css",
      "gitcommit",
      "html",
      "javascript",
      "json",
      "regex",
      "ruby",
      "scss",
      "tsx",
      "typescript",
      "yaml",
    })

    vim.api.nvim_create_autocmd("FileType", { callback = start_treesitter })
  end,
}
