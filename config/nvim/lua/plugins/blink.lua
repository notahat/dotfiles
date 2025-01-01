-- Autocomplete (fast) using the language server.
return {
  "saghen/blink.cmp",
  build = "cargo build --release",
  dependencies = { "rafamadriz/friendly-snippets" },
  opts = {},
}
