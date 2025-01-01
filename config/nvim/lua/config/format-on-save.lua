-- Auto-format files on save using the LSP.

-- Use these clients to format code on save.
local formatters = { "null-ls" }
local filter = function(client)
  return vim.list_contains(formatters, client.name)
end

local augroup = vim.api.nvim_create_augroup("LspFormatting", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function()
    vim.lsp.buf.format({ filter = filter })
  end,
})
