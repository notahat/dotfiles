-- Edit the filesystem like a normal Neovim buffer.
return {
  "stevearc/oil.nvim",
  lazy = true,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    win_options = {
      -- Make space for oil-git-status to show its information.
      signcolumn = "yes:2",
    },
  },
}
