-- Use Mason to install needed tools.
return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  opts = {
    ensure_installed = {
      "bash-language-server",
      "eslint-lsp",
      "shellcheck",
      "lua-language-server",
      "prettierd",
      "stylua",
      "typescript-language-server",
    },
  },
}
