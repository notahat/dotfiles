local bufdelete = require("bufdelete")
local gitsigns = require("gitsigns")
local telescope_builtin = require("telescope.builtin")
local refactoring = require("refactoring")
local actions = require("helpers.actions")

local map = vim.keymap.set

local function map_global_keys()
    -- Leader + upper case for Neo-tree
    map("n", "<leader>B", actions.explore_buffers, { desc = "explore buffers" })
    map("n", "<leader>E", actions.explore_files, { desc = "explore files" })
    map("n", "<leader>F", actions.explore_current_file, { desc = "explore current file" })
    map("n", "<leader>G", actions.explore_git_status, { desc = "explore git status" })

    -- Leader + lower case for lots of other things
    map("n", "<leader><leader>", telescope_builtin.find_files, { desc = "find files" })
    map("n", "<leader>.", telescope_builtin.resume, { desc = "resume last find" })
    map("n", "<leader>/", telescope_builtin.live_grep, { desc = "find in project" })
    map("n", "<leader>b", telescope_builtin.buffers, { desc = "find buffers" })
    map("n", "<leader>d", vim.diagnostic.open_float, { desc = "show diagnostics under cursor" })
    map("n", "<leader>q", actions.write_all_and_quit, { desc = "write all files and quit" })
    map({ "n", "x" }, "<leader>r", refactoring.select_refactor, { desc = "refacor" })
    map("n", "<leader>w", actions.find_word_under_cursor, { desc = "find word under cursor" })
    map("n", "<leader>x", bufdelete.bufdelete, { desc = "close current buffer" })

    -- Run tests
    map("n", "<leader>t.", actions.test_last, { desc = "repeat the last test run" })
    map("n", "<leader>tf", actions.test_file, { desc = "run tests in current file" })
    map("n", "<leader>tn", actions.test_nearest, { desc = "run nearest test" })

    -- Restart things
    map("n", "<leader>ze", actions.restart_eslint, { desc = "restart eslint" })
    map("n", "<leader>zl", vim.cmd.LspRestart, { desc = "restart LSP" })

    -- Move around in the buffer
    map("n", "[g", gitsigns.prev_hunk, { desc = "previous git hunk in buffer" })
    map("n", "]g", gitsigns.next_hunk, { desc = "next git hunk in buffer" })
    map("n", "[q", vim.cmd.cbefore, { desc = "previous quickfix error in buffer" })
    map("n", "]q", vim.cmd.cafter, { desc = "next quickfix error in buffer" })

    -- Navigate between windows
    map("n", "<c-h>", "<c-w>h")
    map("n", "<c-j>", "<c-w>j")
    map("n", "<c-k>", "<c-w>k")
    map("n", "<c-l>", "<c-w>l")

    -- Reselect the visual area when changing indenting in visual mode
    map("v", "<", "<gv")
    map("v", ">", ">gv")
end

-- These mappings only apply when a buffer has a language server attached.
local function map_lsp_keys(args)
    local buffer = args.buf

    map("n", "<leader>c/", telescope_builtin.lsp_document_symbols, { buffer = buffer, desc = "document symbols" })
    map("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = buffer, desc = "code actions" })
    map("n", "<leader>cd", telescope_builtin.diagnostics, { buffer = buffer, desc = "search diagnostics" })
    map("n", "<leader>cr", vim.lsp.buf.rename, { buffer = buffer, desc = "rename symbol under cursor" })

    map("n", "gd", vim.lsp.buf.definition, { buffer = buffer, desc = "Go to defintion" })
    map("n", "gr", telescope_builtin.lsp_references, { buffer = buffer, desc = "Go to references" })
end

-- Configure all the key mappings to my liking.
local function configure()
    map_global_keys()

    local group = vim.api.nvim_create_augroup("lspKeyBindings", { clear = true })
    vim.api.nvim_create_autocmd("LspAttach", { group = group, callback = map_lsp_keys })
end

return { configure = configure }
