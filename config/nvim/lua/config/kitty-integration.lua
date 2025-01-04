-- Tell Kitty when Neovim is open, so it can pass command keys through.
--
-- There's some stuff in kitty.conf to set this up too.
--
-- Code Taken from:
-- https://sw.kovidgoyal.net/kitty/mapping/#conditional-mappings-depending-on-the-state-of-the-focused-window

vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, {
  group = vim.api.nvim_create_augroup("KittySetVarVimEnter", { clear = true }),
  callback = function()
    io.stdout:write("\x1b]1337;SetUserVar=in_editor=MQo\007")
  end,
})

vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
  group = vim.api.nvim_create_augroup("KittyUnsetVarVimLeave", { clear = true }),
  callback = function()
    io.stdout:write("\x1b]1337;SetUserVar=in_editor\007")
  end,
})

-- Make command keys do sensible things.
local everywhere = { "n", "i", "c", "x", "s", "o", "t" }
vim.keymap.set("x", "<d-x>", '"*d', { desc = "Cut" })
vim.keymap.set("x", "<d-c>", '"*ygv', { desc = "Copy" })
vim.keymap.set({ "n", "x" }, "<d-v>", '"*p', { desc = "Paste" })
vim.keymap.set("i", "<d-v>", '<esc>"*pa', { desc = "Paste" })
vim.keymap.set("c", "<d-v>", "<c-R>*", { desc = "Paste" })
vim.keymap.set(everywhere, "<d-s>", vim.cmd.wall, { desc = "Save all" })
vim.keymap.set(everywhere, "<d-q>", vim.cmd.xall, { desc = "Quit" })
vim.keymap.set({ "n", "x" }, "<d-w>", vim.cmd.close, { desc = "Close window" })
vim.keymap.set(everywhere, "<d-z>", vim.cmd.undo, { desc = "Undo" })
