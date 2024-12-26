-- Use space as the leader key.
vim.g.mapleader = " "

-- Use 2 spaces for indentation.
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

-- Use relative line numbering, but display the actual line
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

-- Get rid of the ~ characters on empty lines.
vim.opt.fillchars = { eob = " " }

vim.opt.shortmess:append({
  I = true, -- Don't show the default startup message.
})

-- Disable unused language providers, so checkhealth doesn't complain.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
