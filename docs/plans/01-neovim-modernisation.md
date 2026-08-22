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

**Status: done — two of the three.**

`trouble.nvim` and `bufdelete.nvim` are gone with no loss of function.
`lsp-progress.nvim` stays: it turned out not to be replaceable, see below.
Verified: the status line renders, `<leader>d` and `<leader>x` work, deleting a
buffer leaves the window alive showing the previous buffer, startup is 45-48ms.

### `lsp-progress.nvim` — keep it

This entry was simply wrong, and it took two attempts to find out.

The first attempt swapped it for `vim.ui.progress_status()`. That function only
tracks `Progress` events, which come from progress messages created with
`nvim_echo`. The language server client does not use those — it fires its own
`LspProgress` autocmd (`lsp/handlers.lua:81`) and nothing in the runtime
bridges the two. Measured against a running `lua_ls`: 27 `LspProgress` events,
0 `Progress` events, `vim.ui.progress_status()` empty throughout. The indicator
silently showed nothing.

The obvious next candidate, `vim.lsp.status()` (`lsp.lua:797`), is worse for
this job. Its docs say it "consumes" the latest messages, and that word is
doing a lot of work: it iterates `client.progress`, a ringbuf whose `__call` is
`self:pop()` (`_core/shared.lua:1447`). Calling it destroys what it read.
Measured: 28 non-empty first calls, 0 non-empty second calls. In a status line
— evaluated per window, per redraw — the first window drains the buffer and
every other window renders empty. Poll it slowly and you get every buffered
message concatenated instead of the latest one (226 and 546 character strings
in one workspace load).

`lsp-progress.nvim` avoids all of this by never using either. It hooks the same
`LspProgress` autocmd and keeps its own state, keyed by client and token, so
its `progress()` is a pure idempotent read of a formatted cache. On top of that
it provides four things no built-in does: a 700ms `decay` so messages too fast
to see still register, a 200ms spinner, a 50ms rate limit on its refresh event,
and suppression of that event in insert mode (user events interrupt insert mode
and break which-key style plugins).

One genuine improvement while restoring it: the config now hooks
`LspProgressStatusUpdated` to call `require("lualine").refresh()`, which it
never did before. Progress used to be up to a second stale. Verified: 51 events
and 18 distinct rendered strings during one workspace load, e.g.

```
 LSP [lua_ls] ⣻ Loading workspace 226/232 (97%), Loading workspace 210/210 (100%) - done
```

`vim.ui.progress_status()` is still worth knowing about — it covers progress
from `nvim_echo`, which `vim.pack` and similar use — just not this.

### `trouble.nvim` → fzf-lua

Trouble was only used for `mode = "diagnostics"`, in two places. fzf-lua is
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
position — all cheap to express directly. It would not drop
`nvim-web-devicons`, though: oil and fzf-lua both list it as a dependency of
their own.

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
