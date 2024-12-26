-- Set a decent colorscheme.
return {
  "EdenEast/nightfox.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    local nightfox = require("nightfox")
    nightfox.setup({
      options = { transparent = true },
    })
    vim.cmd.colorscheme("nordfox")
  end,
}
