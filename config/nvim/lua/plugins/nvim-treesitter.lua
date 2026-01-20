-- Provide syntax highlighting and textobjects through the treesitter parser.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({
      "bash",
      "html",
      "javascript",
      "lua",
      "markdown",
      "markdown_inline",
      "query",
      "regex",
      "vim",
      "vimdoc",
    })
  end,
}
