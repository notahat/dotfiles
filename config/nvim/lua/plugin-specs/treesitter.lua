local treesitter_textobjects = {
    move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
            ["]f"] = { query = "@function.outer", desc = "next function" },
            ["]p"] = { query = "@parameter.inner", desc = "next parameter" },
        },
        goto_previous_start = {
            ["[f"] = { query = "@function.outer", desc = "previous function" },
            ["[p"] = { query = "@parameter.inner", desc = "previous parameter" },
        },
    },
    swap = {
        enable = true,
        swap_next = {
            ["<leader>>"] = { query = "@parameter.inner", desc = "move paramater forward" },
        },
        swap_previous = {
            ["<leader><"] = { query = "@parameter.inner", desc = "move parameter backward" },
        },
    },
}

local treesitter_spec = {
    -- https://github.com/nvim-treesitter/nvim-treesitter
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
        -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
        "nvim-treesitter/nvim-treesitter-textobjects",
        -- https://github.com/windwp/nvim-ts-autotag
        "windwp/nvim-ts-autotag",
    },
    build = ":TSUpdate",
    config = function()
        local treesitter = require("nvim-treesitter.configs")
        treesitter.setup({
            auto_install = true,
            autotag = { enable = true },
            highlight = { enable = true },
            textobjects = treesitter_textobjects,
        })

        -- Make Treesitter movements repeatable.
        --
        -- Taken from:
        -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects?tab=readme-ov-file#text-objects-move

        local repeatable_move = require("nvim-treesitter.textobjects.repeatable_move")
        local map = vim.keymap.set
        local nxo = { "n", "x", "o" }

        -- Make , and ; repeat the last Treesitter move.
        map(nxo, ";", repeatable_move.repeat_last_move_next)
        map(nxo, ",", repeatable_move.repeat_last_move_previous)
    end,
}

local mini_ai_spec = {
    "echasnovski/mini.ai",
    dependencies = { treesitter_spec },
    config = function()
        local mini_ai = require("mini.ai")
        mini_ai.setup({
            custom_textobjects = {
                ["a"] = mini_ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
                ["f"] = mini_ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
            },
        })
    end,
}

local refactoring_spec = {
    -- https://github.com/ThePrimeagen/refactoring.nvim
    "ThePrimeagen/refactoring.nvim",
    dependencies = { "nvim-lua/plenary.nvim", treesitter_spec },
    config = function()
        require("refactoring").setup()
    end,
    lazy = true,
}

local treesj_spec = {
    -- https://github.com/Wansmer/treesj
    "Wansmer/treesj",
    dependencies = { treesitter_spec },
    opts = { use_default_keymaps = false },
    lazy = true,
}

return { mini_ai_spec, treesitter_spec, refactoring_spec, treesj_spec }
