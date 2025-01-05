-- Use space as the leader key.
vim.g.mapleader = " "
vim.g.localleader = "\\"

-- Show relative line numbers, but display the actual line
-- number on the current line, and highlight it.
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"
vim.opt.signcolumn = "yes"

-- Make lines wrap at word boundaries and indent the wrapped text.
vim.opt.breakindent = true
vim.opt.linebreak = true

-- Use the mouse for everything and slow down the scroll wheel.
vim.opt.mouse = "a"
vim.opt.mousescroll = "ver:1"

-- Keep a few extra lines on the screen when scrolling.
vim.opt.scrolloff = 3

-- Don't show the default startup message.
vim.opt.shortmess:append({ I = true })

-- Get rid of the ~ characters on empty lines.
vim.opt.fillchars = { eob = " " }

-- Make the ~ command behave like an operator.
vim.opt.tildeop = true

-- Disable unused language providers, so checkhealth doesn't complain.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
