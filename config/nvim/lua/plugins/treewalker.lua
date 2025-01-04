-- Move around using Treesitter syntax nodes.
return {
  "aaronik/treewalker.nvim",
  event = "VeryLazy",
  config = function()
    local treewalker = require("treewalker")

    treewalker.setup({})

    -- Move around Treesitter syntax nodes.
    vim.keymap.set({ "n", "v" }, "<c-h>", treewalker.move_out, { desc = "󰁍 Node out" })
    vim.keymap.set({ "n", "v" }, "<c-j>", treewalker.move_down, { desc = "󰁅 Node down" })
    vim.keymap.set({ "n", "v" }, "<c-k>", treewalker.move_up, { desc = "󰁝 Node up" })
    vim.keymap.set({ "n", "v" }, "<c-l>", treewalker.move_in, { desc = "󰁔 Node in" })

    -- Swap Treesitter syntax nodes.
    vim.keymap.set("n", "<c-s-h>", treewalker.swap_left, { desc = "󰓡 Swap node left" })
    vim.keymap.set("n", "<c-s-j>", treewalker.swap_down, { desc = "󰓢 Swap node down" })
    vim.keymap.set("n", "<c-s-k>", treewalker.swap_up, { desc = "󰓢 Swap node up" })
    vim.keymap.set("n", "<c-s-l>", treewalker.swap_right, { desc = "󰓡 Swap node right" })
  end,
}
