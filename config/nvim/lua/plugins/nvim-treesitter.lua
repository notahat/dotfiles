-- Provide syntax highlighting and textobjects through the treesitter parser.
return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
  build = ":TSUpdate",
  config = function()
    local configs = require("nvim-treesitter.configs")
    configs.setup({
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "lua",
        "markdown",
        "markdown_inline",
        "query",
        "regex",
        "vim",
        "vimdoc",
      },
      ignore_install = {},
      auto_install = true,
      sync_install = false,
      modules = {},

      highlight = { enable = true },

      textobjects = {
        move = {
          enable = true,
          goto_next_start = {
            ["]f"] = { query = "@function.outer", desc = "Next function" },
            ["]p"] = { query = "@parameter.inner", desc = "Next parameter" },
          },
          goto_previous_start = {
            ["[f"] = { query = "@function.outer", desc = "Previous function" },
            ["[p"] = { query = "@parameter.inner", desc = "Previous parameter" },
          },
        },
        select = {
          enable = true,
          include_surrounding_whitespace = true,
          keymaps = {
            ["ab"] = { query = "@block.outer", desc = "block" },
            ["ib"] = { query = "@block.inner", desc = "inner block" },
            ["af"] = { query = "@function.outer", desc = "function" },
            ["if"] = { query = "@function.inner", desc = "inner function" },
            ["ap"] = { query = "@parameter.outer", desc = "parameter" },
            ["ip"] = { query = "@parameter.inner", desc = "inner parameter" },
          },
        },
      },
    })

    local repeatable_move = require("nvim-treesitter.textobjects.repeatable_move")
    vim.keymap.set({ "n", "x", "o" }, ";", repeatable_move.repeat_last_move_next)
    vim.keymap.set({ "n", "x", "o" }, ",", repeatable_move.repeat_last_move_previous)
  end,
}
