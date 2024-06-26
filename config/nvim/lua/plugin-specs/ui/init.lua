-- Show Nicer UI for inputs and selections.
local dressing_spec = {
    -- https://github.com/stevearc/dressing.nvim
    "stevearc/dressing.nvim",
    opts = {},
}

-- Nicer notifications, and LSP progress.
local fidget_spec = {
    -- https://github.com/j-hui/fidget.nvim
    "j-hui/fidget.nvim",
    opts = {
        notification = {
            override_vim_notify = true,
            window = { border = "rounded", relative = "win" },
        },
        progress = {
            display = { done_ttl = 5 },
        },
    },
}

-- Try to break some bad editing habits I've developed.
local hardtime_spec = {
    -- https://github.com/m4xshen/hardtime.nvim
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    opts = { disable_mouse = false },
}

-- Show a lightbulb in the gutter when code actions are available.
local lightbulb_spec = {
    -- https://github.com/kosayoda/nvim-lightbulb
    "kosayoda/nvim-lightbulb",
}

-- Make the status line look clean and pretty.
local lualine_spec = {
    -- https://github.com/nvim-lualine/lualine.nvim
    "nvim-lualine/lualine.nvim",
    opts = require("plugin-specs.ui.lualine-opts"),
}

-- I haven't settled on a colorscheme that I love, but this one isn't bad.
--
-- I liked good old jellybeans more, but that doesn't have support for all the
-- modern Treesitter formatting.
local nightfox_spec = {
    -- https://github.com/EdenEast/nightfox.nvim
    "EdenEast/nightfox.nvim",
    opts = {
        groups = {
            all = {
                -- Darken selection to give more contrast with text.
                -- This works nicely against our black background.
                CursorLine = { bg = "#22262f" },
                Visual = { bg = "#22262f" },

                -- Work around this issue:
                -- https://github.com/EdenEast/nightfox.nvim/issues/440
                NeoTreeTitleBar = { fg = "#131a24", bg = "#71839b" },
            },
        },
        options = { transparent = true },
    },
    lazy = false,
    priority = 1000,
}

-- Show key mappings in a box at the bottom of the screen.
--
-- This is very useful when I'm tinkering with key mappings and I can't
-- remember what I've done.
local which_key_spec = {
    -- https://github.com/folke/which-key.nvim
    "folke/which-key.nvim",
    config = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
    end,
}

return {
    dressing_spec,
    fidget_spec,
    hardtime_spec,
    lightbulb_spec,
    lualine_spec,
    nightfox_spec,
    which_key_spec,
}
