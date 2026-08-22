-- Format files on save.
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      css = { "prettierd" },
      html = { "prettierd" },
      javascript = { "prettierd" },
      javascriptreact = { "prettierd" },
      json = { "prettierd" },
      jsonc = { "prettierd" },
      less = { "prettierd" },
      lua = { "stylua" },
      markdown = { "prettierd" },
      ["markdown.mdx"] = { "prettierd" },
      ruby = { "syntax_tree" },
      scss = { "prettierd" },
      typescript = { "prettierd" },
      typescriptreact = { "prettierd" },
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
    format_on_save = {
      timeout_ms = 500,
    },
  },
}
