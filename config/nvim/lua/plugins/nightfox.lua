-- Set a decent colorscheme.
return {
  "EdenEast/nightfox.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    local nightfox = require("nightfox")
    nightfox.setup({
      groups = {
        all = {
          -- Darken selection to give more contrast with text.
          -- This works nicely against a black background.
          CursorLine = { bg = "#22262f" },
          Visual = { bg = "#22262f" },
        },
      },
      options = { transparent = true },
    })
    vim.cmd.colorscheme("nordfox")
  end,
}
