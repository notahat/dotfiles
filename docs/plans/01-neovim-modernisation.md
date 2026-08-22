# Neovim Modernisation

A review of `config/nvim` against Neovim 0.12.4, looking for plugins that newer
built-in functionality can replace, plugins with newer alternatives, and config
that has become redundant.

Every claim below was checked against the installed runtime
(`/opt/homebrew/Cellar/neovim/0.12.4/share/nvim/runtime`) or against the
installed plugin sources, not from memory.

Items are roughly in order of value.

## 1. Treesitter highlighting isn't actually on

**Status: done.**

This is a bug, not a modernisation. The `main` branch of `nvim-treesitter` no
longer enables highlighting — it is install-only now. Its README says so
explicitly, and `lua/plugins/nvim-treesitter.lua` only called `install()`.
Nothing in the config ever called `vim.treesitter.start()`.

Core only starts treesitter for four filetypes (`ftplugin/{lua,markdown,help,
query}.lua` in the runtime). So the `bash`, `html`, `javascript`, `regex`,
`vim`, and `vimdoc` parsers were installed and unused for highlighting —
everything else fell back to regex syntax.

The fix is a `FileType` autocmd:

```lua
vim.api.nvim_create_autocmd("FileType", {
  callback = function(event)
    pcall(vim.treesitter.start, event.buf)
  end,
})
```

Two follow-ons:

- **Trim the install list.** Neovim 0.12 bundles the `c`, `lua`, `markdown`,
  `markdown_inline`, `query`, `vim`, and `vimdoc` parsers (in
  `lib/nvim/parser/`). Six of the ten entries were redundant.
- **Add the missing parsers.** The config runs `ts_ls`, `eslint`, and (at work)
  `sorbet`, and formats `typescript`, `typescriptreact`, `ruby`, `json`, and
  `scss` — but installed none of those parsers. So `treesj`, the textobjects,
  and `treewalker` silently did nothing in the languages used most.

Verified after the change: treesitter highlighting is now active for `sh`,
`typescript`, `ruby`, `yaml`, `scss`, and `markdown`; filetypes with no parser
(`text`, `dockerfile`) start cleanly thanks to the `pcall`; startup is 48ms.

One loose end: nvim-treesitter installs parsers into
`~/.local/share/nvim/site/parser/`, and it doesn't remove ones dropped from the
install list. The `lua`, `markdown`, `markdown_inline`, `query`, `vim`, and
`vimdoc` parsers are now orphaned there (as is an older set under
`~/.local/share/nvim/lazy/nvim-treesitter/parser/`, including `python`, `tmux`,
`toml`, and `cmake`). Harmless — they just shadow the bundled ones — but
`:TSUninstall` will clear them out.

## 2. Plugins 0.12 can now replace outright

**Status: done.**

Three plugins gone with no loss of function. Verified afterwards: the status
line still renders, `<leader>d` and `<leader>x` still work, deleting a buffer
leaves the window alive showing the previous buffer, and startup is 45-48ms.

One deliberate omission. Lualine polls once a second, so LSP progress can lag
by up to that long. The old `lsp-progress.nvim` setup had exactly the same lag,
because the config never hooked up its `LspProgressStatusUpdated` event, so
this is no worse than before. If it ever grates, 0.12 added a `Progress`
autocmd event that can drive `require("lualine").refresh()` directly.

### `lsp-progress.nvim` → `vim.ui.progress_status()`

New in 0.12, built in. Drop the plugin and the `lsp_progress` helper in
`lualine.lua`:

```lua
lualine_x = { { vim.ui.progress_status, on_click = show_lsp_info } },
```

### `trouble.nvim` → fzf-lua

Trouble is only used for `mode = "diagnostics"`, in two places. fzf-lua is
already loaded, so `require("fzf-lua").diagnostics_workspace()` covers it with a
picker UI consistent with the rest of the bindings.

0.12 also added `vim.lsp.buf.workspace_diagnostics()` if the quickfix list is
preferable.

### `bufdelete.nvim` → a few lines

The plugin exists to delete a buffer without wrecking the window layout:

```lua
local function delete_buffer()
  local buffer = vim.api.nvim_get_current_buf()
  vim.cmd.bprevious()
  vim.api.nvim_buf_delete(buffer, {})
end
```

Not byte-for-byte equivalent — the plugin also handles the same buffer being
open in several windows — but almost certainly equivalent in practice here.

## 3. Redundant config to delete

**Status: done.**

- **The `texthl` block in `diagnostics.lua`.** `vim.diagnostic.Opts.Signs`
  accepts `severity`, `priority`, `text`, `numhl`, and `linehl` — there is no
  `texthl` field, and the string does not appear anywhere in
  `runtime/lua/vim/diagnostic.lua`. Sign highlights come from an internal
  `sign_highlight_map` (`diagnostic.lua:1791`), so the block was inert rather
  than merely redundant. Deleting it changes nothing visually.
- **`gitsigns.next_hunk` / `prev_hunk` are deprecated.** Confirmed in the
  installed copy at `actions.lua:562` and `:584`. Now using `nav_hunk("next")`
  and `nav_hunk("prev")`.
- **`mason.nvim`'s `ui.border = "none"`** fought the global
  `vim.opt.winborder = "rounded"` set in `options.lua`. Mason's own default is
  `border = nil`, documented as "Defaults to `:h 'winborder'` if nil"
  (`settings.lua:120`), so dropping the override lets Mason match every other
  float.

Verified afterwards: the error sign still renders with `DiagnosticSignError`,
`]g` jumps to the first hunk in a test repo and reports "Hunk 1 of 2", Mason's
resolved border is now nil against a rounded `winborder`, and startup is 44ms.

## 4. Newer alternatives and API drift

**Status: not done.**

### Mason moved

`williamboman/mason.nvim` was transferred to `mason-org/mason.nvim` (Mason v2).
The old path still redirects but is unmaintained. Worth confirming and updating
the spec — or see below.

### Consider dropping Mason entirely

The dotfiles already have a Brewfile with a Coding section and a per-environment
mise config. `lua-language-server`, `stylua`, `shellcheck`, and
`typescript-language-server` are all in Homebrew. `prettierd`,
`bash-language-server`, and `eslint-lsp` are npm packages and `stree` is a gem,
but mise handles both backends (`mise use -g npm:prettierd`,
`gem:syntax_tree`).

That removes two plugins and puts tool versions under the same lockfiles as
everything else in the dotfiles.

The counter-argument: it becomes four packages split across three managers
instead of one list. It fits the dotfiles better than it fits the nvim config.

### Default LSP mappings not yet used

0.12 added `grt` (`vim.lsp.buf.type_definition()`) and `grx`
(`vim.lsp.codelens.run()`) alongside the `gri` and `grr` already overridden in
`key-mappings.lua`. There is also a new `:lsp` command for managing clients
interactively.

## 5. Bolder moves

**Status: not done.**

### `blink.cmp` → built-in autocompletion

The big one. 0.12 shipped `'autocomplete'`, `'autocompletedelay'`, and
`'autocompletetimeout'`; `'complete'` gained `o` (omnifunc) and `F` (function)
sources; `'completeopt'` gained `popup` and `nearest`; and `'pumborder'` exists.
Combined with `vim.lsp.completion.enable({ autotrigger = true })` and built-in
`vim.snippet`, that is `blink.cmp` and `friendly-snippets` both gone.

The cost is blink's cross-source ranking and ghost text. See
`:help ins-autocompletion` — there is a worked example at `insert.txt:1135`.

### `lualine` → the default statusline

0.12's default statusline is now a plain statusline expression, and already
shows `vim.diagnostic.status()`, `vim.ui.progress_status()`, `'busy'`, and
terminal exit codes. The lualine config adds mode, a shortened path, and
position — all cheap to express directly. Dropping it also drops
`nvim-web-devicons`, if oil and fzf-lua are its only other users.

This suits the README's "minimal UI, fast startup" stance, but it is the one
item here that costs something visual.

### `lazy.nvim` → `vim.pack`

Real, and built in. **Recommendation: stay on lazy for now.** There are 22
plugins, a lockfile the config relies on, and a sub-100ms startup target that
lazy-loading protects. `vim.pack` has no lockfile equivalent yet.

## Also new, unrelated to plugins

- `:Undotree` and `:DiffTool` ship as built-in opt plugins
  (`:packadd nvim.undotree`, `:packadd nvim.difftool`).
- `'exrc'` now loads project-local config from parent directories too.
