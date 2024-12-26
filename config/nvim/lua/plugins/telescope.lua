-- Telescope does fuzzy finding over all sorts of things.
return {
  "nvim-telescope/telescope.nvim",
  lazy = true,
  dependencies = {
    "folke/noice.nvim",
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        layout_strategy = "vertical",
      },
    })
    telescope.load_extension("fzf")
    telescope.load_extension("noice")
  end,
}
