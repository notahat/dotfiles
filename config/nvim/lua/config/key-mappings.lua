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

local function telescope_buffers()
  require("telescope.builtin").buffers()
end

local function telescope_find_files()
  require("telescope.builtin").find_files()
end

local function telescope_help_tags()
  require("telescope.builtin").help_tags()
end

local function telescope_live_grep()
  require("telescope.builtin").live_grep()
end

local function telescope_lsp_definitions()
  require("telescope.builtin").lsp_definitions()
end

local function telescope_lsp_implementation()
  require("telescope.builtin").lsp_implementations()
end

local function telescope_lsp_references()
  require("telescope.builtin").lsp_references()
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

-- local function telescope_marks()
--   require("navimark.tele").open_mark_picker()
-- end

local function telescope_grep_string()
  require("telescope.builtin").grep_string()
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

vim.keymap.set("n", "<leader><leader>", telescope_find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>b", telescope_buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>d", open_diagnostics, { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>h", telescope_help_tags, { desc = "Help" })
vim.keymap.set("n", "<leader>j", toggle_join, { desc = "Join/split" })
-- vim.keymap.set("n", "<leader>m", toggle_mark, { desc = "Toggle mark" })
-- vim.keymap.set("n", "<leader>M", telescope_marks, { desc = "Marks" })
-- vim.keymap.set("n", "<leader>n", open_notifications, { desc = "Notifications" })
vim.keymap.set("n", "<leader>q", vim.cmd.xall, { desc = "Quit" })
vim.keymap.set("n", "<leader>r", search_and_replace, { desc = "Search and replace" })
vim.keymap.set("n", "<leader>w", vim.cmd.wall, { desc = "Write all" })
vim.keymap.set("n", "<leader>x", delete_buffer, { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>/", telescope_live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>*", telescope_grep_string, { desc = "Live grep word under cursor" })

vim.keymap.set("n", "-", open_oil, { desc = "Oil" })

-- Jump between git changes in the buffer.
vim.keymap.set({ "n", "x" }, "[g", previous_git_hunk, { desc = "Previous git hunk" })
vim.keymap.set({ "n", "x" }, "]g", next_git_hunk, { desc = "Next git hunk" })

-- Replace the standard LSP actions with nicer versions.
-- require("which-key").add({ "gr", group = "LSP actions" })
vim.keymap.set("n", "gra", vim.lsp.buf.code_action, { desc = "Code actions" })
vim.keymap.set("n", "gri", telescope_lsp_implementation, { desc = " Implementation" })
vim.keymap.set("n", "grn", vim.lsp.buf.rename, { desc = "Rename" })
vim.keymap.set("n", "grr", telescope_lsp_references, { desc = " References" })

-- Add LSP definition lookup too, in the same style as the above.
vim.keymap.set("n", "grd", telescope_lsp_definitions, { desc = " Definitions" })

-- Reselect the visual area when changing indenting in visual mode.
vim.keymap.set("x", "<", "<gv", { desc = "Unindent" })
vim.keymap.set("x", ">", ">gv", { desc = "Indent" })
