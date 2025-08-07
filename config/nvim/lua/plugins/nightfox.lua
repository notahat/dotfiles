-- Set a decent colorscheme.
return {
  "EdenEast/nightfox.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    local nightfox = require("nightfox")

    nightfox.setup({
      options = {
        -- Use a black background.
        transparent = true,
      },
      groups = {
        all = {
          -- Darken the selection to give more contrast with text.
          CursorLine = { bg = "#404859" },
          Visual = { bg = "#404859" },
        },
      },
      specs = {
        nordfox = {
          diag_bg = {
            -- Darken the background of diagnostic messages too.
            error = "#1a1c21",
            warn = "#1a1c21",
            info = "#1a1c21",
            hint = "#1a1c21",
            ok = "#1a1c21",
          },
        },
      },
    })

    vim.cmd.colorscheme("nordfox")
  end,
}
