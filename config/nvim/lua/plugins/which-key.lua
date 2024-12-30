-- Show key mappings in a box at the bottom of the screen.

local function show_which_key()
  require("which-key").show()
end

return {
  "folke/which-key.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    icons = { mappings = false },
    preset = "helix",
  },
  keys = {
    { "<leader>?", show_which_key, desc = "Global keys" },
  },
}
