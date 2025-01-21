-- Set and search for bookmarks.
--
-- Currently this isn't lazy-loadable, and it forces Telescope into loading on
-- startup too. Plus it's got a 10ms+ startup time. If I get a chance, I'll see
-- if I can improve this.

return {
  "zongben/navimark.nvim",
  enabled = false,
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  opts = {
    keymap = {
      base = {
        mark_toggle = "",
        mark_add = "",
        mark_remove = "",
        goto_next_mark = "",
        goto_prev_mark = "",
        open_mark_picker = "",
      },
    },
  },
}
