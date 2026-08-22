# Simplification review

A pass over the install machinery, the steps, the zsh and Neovim configs, and
the Claude statusline, looking for code that could be simpler or clearer.

Most of the repo is already about as lean as it can be. The items below are
ranked by how much simplicity each one buys. Items 1 to 3 are the ones worth
doing; the rest are smaller.

## Status

- [x] 1. Collapse `statusline.sh` to a single `jq` pass
- [x] 2. Let `link_file` create the parent directory
- [x] 3. Pull the shared shell helpers into one file
- [x] 4. Make `install` work from any directory
- [x] 5. Validate the step name
- [x] 6. Replace the `git config` calls with an included gitconfig
- [ ] 7. Small stuff
- [x] 8. Run the steps as programs instead of sourcing them

## 1. Collapse `statusline.sh` to a single `jq` pass

`config/claude/statusline.sh` runs nine separate `jq` subprocesses over the
same input, then repeats the same "round a float to an integer" dance four
times and the same "append a reset time" dance twice. Around 60 lines doing
about 15 lines of work, forking 9+ processes on every render.

Extract every field in one `jq` pass, and factor the two repeated shapes into
functions:

```bash
# Pull every field out in one pass, as `name=value` lines. Missing fields come
# back empty.
eval "$(jq -r '
  @sh "model=\(.model.display_name // "")",
  @sh "directory=\(.workspace.current_dir // "")",
  ...
')"

# Renders a rate limit as "5h: 18% resets 14:00". Renders nothing when Claude
# gave us no percentage for it.
function format_rate_limit {
  local label=$1 percentage=$2 resets_at=$3 reset_format=$4
  ...
}
```

That drops the four `ctx_int` / `five_int` / `week_int` temporaries and the
repeated reset-time blocks.

**Done.** The rewrite renders byte-identical output across 11 sample payloads
covering missing fields, token counts either side of the 1k and 1M thresholds,
rate limits with and without reset times, and directories with spaces. It did
not make the file shorter: 49 code lines before, 54 after, because the
extracted functions carry header comments. What it bought was the removal of
the duplicated formatting logic and a 3.4x speedup, from about 60ms per render
down to 18ms, measured over 50 renders of a full payload.

One deliberate behaviour change: with `model` or `current_dir` absent, the old
script printed the literal string `null`, because those two fields were the
only ones without a `// empty` fallback. The rewrite prints an empty string.
Neither field goes missing in practice.

Two smaller problems in the same file. It declares `#!/bin/bash` but is
written in POSIX `[ ]` and `$(( ))` style throughout, so it reads as two
dialects mixed together. And it carries no header comment, so you have to
reconstruct the output format by reading the whole script.

## 2. Let `link_file` create the parent directory

`mkdir -p` appears 13 times across `steps/`, almost always directly above a
`link_file` into that directory. It is ceremony, and it is easy to forget when
adding a step.

```bash
function link_file {
  mkdir -p "$(dirname "$2")"
  if [[ -L "$2" ]]; then
  ...
```

That removes 11 of the 13 lines. `steps/bat.bash` becomes one line, and so do
`steps/ghostty.bash` and `steps/rancher-desktop.bash`.

**Done.** The two `mkdir` calls that stayed both do more than ensure a link
parent exists: `fetch_skill` creates a directory it curls a file into, and
`claude.bash` creates `~/.claude/hooks`, which nothing links into yet (see item
7). `steps/ssh.bash` now runs its `chmod 700` after the link rather than
before, since `link_file` is what creates `~/.ssh`; checked the result is still
`drwx------` against a throwaway `HOME`. Every link-only step re-run clean and
idempotent, and `shellcheck` passes on `install`, `upgrade` and all the steps.

## 3. Pull the shared shell helpers into one file

`upgrade` copies `green`, `reset`, and `echo_green` verbatim from `install`.
`steps/claude.bash` calls `echo_red`, which works only because `install`
sources the steps rather than executing them. That dependency is invisible
from inside the step.

A `lib/output.bash` holding the colour helpers, sourced by both `install` and
`upgrade`, removes the duplication and makes the dependency explicit.

**Done**, and later reworked by item 8. The first pass put the helpers in
`lib/output.bash` and left the steps inheriting them, which needed two
`# shellcheck disable=SC2154` comments once the steps started reading
`$dotfiles_dir`.

## 4. Make `install` work from any directory

```bash
steps_dir="$(dirname "$0")/steps"                          # works from anywhere
ln -s "$PWD/$1" "$2"                                       # repo root only
brew bundle --file "environments/$DOTFILES_ENV/Brewfile"   # repo root only
```

The `dirname "$0"` implies you can run `~/.dotfiles/install` from somewhere
else. Do that and `link_file` creates symlinks pointing at `$PWD/config/...`,
which are broken, with no error. Have the script find its own root and use it
everywhere:

```bash
dotfiles_dir="$(cd "$(dirname "$0")" && pwd)"
```

Then `ln -s "$dotfiles_dir/$1"` and `--file "$dotfiles_dir/environments/..."`.

**Done.** Two cwd-dependent spots turned up beyond the ones listed above.
`steps/zsh.bash` ran `git submodule update` against whatever directory you
happened to be in, so it now passes `-C "$dotfiles_dir"`. And `steps/mise.bash`
still runs a bare `mise install`, which picks up a `mise.toml` in the current
directory if there is one; the global config it needs is symlinked, so that is
left alone.

Verified by running `install bat` and `install zed` from `/` into a throwaway
`HOME`. The symlinks point at `/Users/notahat/.dotfiles/config/...` and all
resolve. Before this change they would have pointed at `/config/...`.

The two steps reading `$dotfiles_dir` need a `# shellcheck disable=SC2154`,
since the linter cannot see that `install` sets it before sourcing them.

## 5. Validate the step name

`./install nosuchstep` prints:

```
./install: line 35: ./steps/nosuchstep.bash: No such file or directory
```

A typo deserves the usage message that is already written:

```bash
function run_step {
  if [[ ! -f "$steps_dir/$1.bash" ]]; then
    echo_red "Unknown step: $1"
    usage
  fi
  ...
```

While in there: `usage` prints `install [step name]` twice, once at the top and
again under "Run a single step". Drop the first one.

**Done.** `./install nosuchstep` now names the step, prints the usage, and
exits 1.

## 6. Replace the `git config` calls with an included gitconfig

`steps/git.bash` is the one step where the config is not a config file. Twenty
`git config --global` calls, re-run on every install, setting values that never
change. A checked-in gitconfig is easier to read and to diff:

```ini
# config/git/gitconfig
[user]
  name = Pete Yandell
  email = pete@notahat.com
  signingkey = ssh-ed25519 AAAAC3...
[commit]
  gpgsign = true
```

`~/.config/git/config` needs to stay a real file so git can write to it, which
is what the `touch` is for, so seed it with an include rather than symlinking
it. Same reasoning as the comment about Claude skills in `steps/claude.bash`:

```bash
touch ~/.config/git/config
git config --global include.path "$dotfiles_dir/config/git/gitconfig"
```

The step drops to three lines and the git settings become reviewable in a diff.

**Done.** The step went from 26 lines of `git config` to the two lines above,
and `config/git/gitconfig` holds the settings.

Equivalence was checked by running the old step into a throwaway `HOME`,
recording `git config --global --list --includes`, then running the new step
into a fresh `HOME` and diffing. The only difference is `core.excludesfile`,
which reads as `~/.config/git/ignore` instead of a pre-expanded absolute path.
`git config --get --type=path` resolves it to the same file, and a global
ignore entry was confirmed to still take effect.

Note that `--list` only follows includes when passed `--includes`, or when no
`--global`/`--file` scope is given. Ordinary lookups always follow them.

`~/.config/git/config` on this machine already held the same values written out
by the old step, so it was backed up to `config.backup-before-include` and
replaced with the include alone. Without that, the settings would be defined in
both places.

## 7. Small stuff

- `docs/agents/` is empty. Delete it or fill it.
- The README says the install fetches `grill-me` by Matt Pocock.
  `steps/claude.bash` fetches only `doc-coauthoring`. The README also says
  hooks live in `config/claude`, and there are none, though `claude.bash`
  creates `~/.claude/hooks`.
- `config/nvim/lua/plugins/conform.lua:6` has a commented-out `log_level` line.
- `config/nvim/lua/config/key-mappings.lua` defines 17 near-identical one-line
  wrappers to defer the `require` calls. A helper would collapse them:

  ```lua
  local function lazy(module, method)
    return function() require(module)[method]() end
  end

  vim.keymap.set("n", "<leader>b", lazy("fzf-lua", "buffers"), { desc = "Buffers" })
  ```

  This one is a real trade-off. The current wrappers are greppable and the
  indirection costs the reader something. Worth taking only if the list keeps
  growing.

## 8. Run the steps as programs instead of sourcing them

`install` used to `source` each step, so a step silently inherited
`link_file`, `echo_red` and `dotfiles_dir`. Nothing in a step said where any of
that came from, and shellcheck could not see the variables, which is what the
two `disable=SC2154` comments were papering over.

The first alternative considered was a `dotfiles_path` helper, on the grounds
that shellcheck trips on bare variables but not on function calls. That would
have silenced the linter while leaving the inheritance in place.

Each step is now an executable that sources `lib/dotfiles.bash` itself:

```bash
#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"
```

The lib works out `dotfiles_dir` from `${BASH_SOURCE[0]}`, so it holds whether
`install` or a step does the sourcing, and nothing needs passing in.

What it cost: sourcing was load-bearing for the `PATH`. `homebrew.bash` ran
`eval "$(brew shellenv)"`, which was what put `mise` on the `PATH` for the step
after it. `install` now exports a `PATH` once, up front, mirroring what
`config/zsh/zshenv` sets up for an interactive shell. That let `mise.bash` drop
its own `export PATH` and flatten a nested `if`. The per-step cost is three
lines of preamble, about 39 lines across the 13 steps.

`.shellcheckrc` turns on `external-sources` and `source-path=SCRIPTDIR`, so
plain `shellcheck` follows the `source` from any working directory, and the
editor's bashls reads the same file. Both `disable=SC2154` comments are gone,
and the checking is stronger rather than suppressed: verified by adding a bogus
variable to a step and confirming SC2154 still fires on it.

Also verified: steps run standalone with no `install` involved, so
`steps/bat.bash` on its own works; a failing step still aborts `install` with a
non-zero exit; links created from `/` point into the repo and resolve; and
every link-only step is still idempotent against the real `HOME`.

Left alone: `mise.bash` runs `eval "$(mise activate bash)"`, which affects only
its own process. It looks removable, but `mise install` is not something I could
test safely, so it stays.
