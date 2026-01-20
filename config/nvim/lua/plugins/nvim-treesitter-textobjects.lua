-- Manipulate text objects using treesitter.

local function select_outer_block()
  require("nvim-treesitter-textobjects.select").select_textobject("@block.outer", "textobjects")
end

local function select_inner_block()
  require("nvim-treesitter-textobjects.select").select_textobject("@block.inner", "textobjects")
end

local function select_outer_function()
  require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
end

local function select_inner_function()
  require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
end

local function select_outer_parameter()
  require("nvim-treesitter-textobjects.select").select_textobject("@parameter.outer", "textobjects")
end

local function select_inner_parameter()
  require("nvim-treesitter-textobjects.select").select_textobject("@parameter.inner", "textobjects")
end

local function next_function()
  require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
end

local function previous_function()
  require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
end

local function next_parameter()
  require("nvim-treesitter-textobjects.move").goto_next_start("@parameter.inner", "textobjects")
end

local function previous_parameter()
  require("nvim-treesitter-textobjects.move").goto_previous_start("@parameter.inner", "textobjects")
end

return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  branch = "main",
  init = function()
    -- Disable entire built-in ftplugin mappings to avoid conflicts.
    -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
    vim.g.no_plugin_maps = true

    -- Or, disable per filetype (add as you like)
    -- vim.g.no_python_maps = true
    -- vim.g.no_ruby_maps = true
    -- vim.g.no_rust_maps = true
    -- vim.g.no_go_maps = true
  end,
  config = function()
    require("nvim-treesitter-textobjects").setup({})

    vim.keymap.set({ "x", "o" }, "ab", select_outer_block, { desc = "block" })
    vim.keymap.set({ "x", "o" }, "ib", select_inner_block, { desc = "inner block" })
    vim.keymap.set({ "x", "o" }, "af", select_outer_function, { desc = "function" })
    vim.keymap.set({ "x", "o" }, "if", select_inner_function, { desc = "inner function" })
    vim.keymap.set({ "x", "o" }, "ap", select_outer_parameter, { desc = "parameter" })
    vim.keymap.set({ "x", "o" }, "ip", select_inner_parameter, { desc = "inner parameter" })

    vim.keymap.set({ "n", "x", "o" }, "]f", next_function, { desc = "Next function" })
    vim.keymap.set({ "n", "x", "o" }, "[f", previous_function, { desc = "Previous function" })
    vim.keymap.set({ "n", "x", "o" }, "]p", next_parameter, { desc = "Next parameter" })
    vim.keymap.set({ "n", "x", "o" }, "[p", previous_parameter, { desc = "Previous parameter" })

    local repeatable_move = require("nvim-treesitter-textobjects.repeatable_move")
    vim.keymap.set({ "n", "x", "o" }, ";", repeatable_move.repeat_last_move_next)
    vim.keymap.set({ "n", "x", "o" }, ",", repeatable_move.repeat_last_move_previous)
  end,
}
