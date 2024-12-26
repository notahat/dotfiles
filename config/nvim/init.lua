-- Highlights of this config are:
--
-- * Plugin management with lazy.nvim
-- * Automatic installation of language servers and formatters with mason.nvim
-- * Language server support with nvim-lspconfig
-- * Auto-formatting with null-ls
-- * Completion with nvim-cmp
-- * Syntax highlighting with nvim-treesitter
-- * File explorer with oil.nvim
-- * Fuzzy finding of all sorts of things with Telescope
--
-- I keep the UI much more minimal than a normal IDE. I'm easily distracted, so
-- I want my code front-and-centre with not too much other information.

require("config.options")
require("config.lazy")
require("config.key-mappings")
require("config.auto-format")
require("config.kitty-integration")
