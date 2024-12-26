-- Fast autocomplete.
return {
  "saghen/blink.cmp",
  build = "cargo build --release",
  dependencies = { "rafamadriz/friendly-snippets" },
  opts = {},
}
