-- Tip: Make sure to require plugins inside of functions, to help with lazy loading.

local function delete_buffer()
  require("bufdelete").bufdelete()
end

local function open_diagnostics()
  require("trouble").open({ mode = "diagnostics", auto_close = true })
end

-- local function open_notifications()
--   require("noice").cmd("all")
-- end

local function open_oil()
  require("oil").open()
end

local function fzf_buffers()
  require("fzf-lua").buffers()
end

local function fzf_find_files()
  require("fzf-lua").files()
end

local function fzf_help_tags()
  require("fzf-lua").helptags()
end

local function fzf_live_grep()
  require("fzf-lua").live_grep_native()
end

local function fzf_lsp_definitions()
  require("fzf-lua").lsp_definitions()
end

local function fzf_lsp_implementation()
  require("fzf-lua").lsp_implementations()
end

local function fzf_lsp_references()
  require("fzf-lua").lsp_references()
end

local function toggle_join()
  require("treesj").toggle()
end

local function next_git_hunk()
  require("gitsigns").next_hunk()
end

local function previous_git_hunk()
  require("gitsigns").prev_hunk()
end

local function search_and_replace()
  require("grug-far").open()
end

-- local function toggle_mark()
--   require("navimark.stack").mark_toggle()
-- end

-- local function fzf_marks()
--   require("navimark.tele").open_mark_picker()
-- end

local function fzf_grep_string()
  require("fzf-lua").grep_cword()
end

-- Tip: Try to have few custom mappings, and use built-in mappings as much as
-- possible. Stick to mostly "<leader>*" mappings, rather than going deeper.

-- The first parameter to `vim.keymap.set` is the modes in which the mappings
-- apply.
--
-- Neovim's modes are:
--   n = Normal mode
--   i = Insert mode
--   c = Command mode, typing a command after hitting ":"
--   x = Visual mode, when text is selected
--   s = Select mode, text is selected and will be replaced with typing
--   o = Operator-pending mode, waiting for an operator after d, y, c, etc.
--   t = Terminal mode, inside a terminal
--   l = Lang-arg mode, used for language mappings
--
-- "v" is a shortcut for both visual (x) and select (s) modes.
--
-- An empty string means normal (n), visual (x), select (s), and
-- operator-pending (o) modes.
--
-- See Neovim's help for map-modes

vim.keymap.set("n", "<leader><leader>", fzf_find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>b", fzf_buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>d", open_diagnostics, { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>h", fzf_help_tags, { desc = "Help" })
vim.keymap.set("n", "<leader>j", toggle_join, { desc = "Join/split" })
-- vim.keymap.set("n", "<leader>m", toggle_mark, { desc = "Toggle mark" })
-- vim.keymap.set("n", "<leader>M", fzf_marks, { desc = "Marks" })
-- vim.keymap.set("n", "<leader>n", open_notifications, { desc = "Notifications" })
vim.keymap.set("n", "<leader>q", vim.cmd.xall, { desc = "Quit" })
vim.keymap.set("n", "<leader>r", search_and_replace, { desc = "Search and replace" })
vim.keymap.set("n", "<leader>w", vim.cmd.wall, { desc = "Write all" })
vim.keymap.set("n", "<leader>x", delete_buffer, { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>/", fzf_live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>*", fzf_grep_string, { desc = "Live grep word under cursor" })

vim.keymap.set("n", "-", open_oil, { desc = "Oil" })

-- Jump between git changes in the buffer.
vim.keymap.set({ "n", "x" }, "[g", previous_git_hunk, { desc = "Previous git hunk" })
vim.keymap.set({ "n", "x" }, "]g", next_git_hunk, { desc = "Next git hunk" })

-- Replace the standard LSP actions with nicer versions.
vim.keymap.set("n", "gri", fzf_lsp_implementation, { desc = " Implementation" })
vim.keymap.set("n", "grr", fzf_lsp_references, { desc = " References" })

-- Add LSP definition lookup too, in the same style as the above.
vim.keymap.set("n", "grd", fzf_lsp_definitions, { desc = " Definitions" })

-- Reselect the visual area when changing indenting in visual mode.
vim.keymap.set("x", "<", "<gv", { desc = "Unindent" })
vim.keymap.set("x", ">", ">gv", { desc = "Indent" })
