# Pete's dotfiles

I've been refining these dotfiles since 2010. They do 80% of the work of
setting up a Mac the way I like it:

```sh
xcode-select --install
git clone https://github.com/notahat/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install
```

I keep them lean. Anything I stop using I delete, so what's left is what I run
every day.

## Highlights worth stealing

- **A tiny install you can read.** `./install` runs plain-bash steps
  from [`steps/`](steps). It symlinks config into place, and it's idempotent,
  so I re-run it any time I add a step. If a config file already exists, it
  warns and skips rather than clobbering it.
- **A clear rule for Homebrew vs. Mise.** [Homebrew](https://brew.sh) installs
  anything I always want at the latest version (apps, CLI tools, even Mac App
  Store apps). [Mise](https://mise.jdx.dev) manages anything I need pinned to a
  particular version, like language runtimes.
- **Zsh that starts in under 100ms.** A [Starship](https://starship.rs) prompt,
  fzf-tab completion, and syntax highlighting, wired up by hand in
  [`config/zsh`](config/zsh).
- **Neovim, under 100ms too.** LSP, Treesitter, and fuzzy finding, with the UI
  stripped back so the code is the only thing on screen. It's commented
  throughout and has [its own README](config/nvim).
- **One command to update everything.** `./upgrade` bumps Homebrew packages,
  Mise tools, Neovim plugins, and borrowed Claude Code skills.
- **Claude Code skills, homegrown and borrowed.** Mine live in
  [`config/claude`](config/claude), symlinked into `~/.claude` alongside my
  settings and statusline. Other people's I install from their source repos
  with [`npx skills`](https://github.com/vercel-labs/skills), so I'm not
  redistributing anyone's work.

It's all [MIT licensed](LICENSE), so take what's useful.

## How it works

`./install` runs the steps in [`steps/`](steps), each a small bash script that
installs a tool and symlinks its config. Run them all, or one at a time:

```sh
./install         # everything
./install zsh     # just the zsh step
./install -h      # usage, and the list of steps
```

The pieces:

- [`config/`](config): every config file, one directory per tool. The steps
  symlink most of them into `~` and `~/.config`.
- [`project-templates/`](project-templates): drop-in editor and tooling config
  for new Rails and Vite projects.

### Work machines

I use these dotfiles at work too, where I need different tools and some config
I'd rather not publish. Rather than fork, I keep the work-only bits in a second,
private repo with its own `steps/` directory, cloned by hand to
`~/.dotfiles-ferocia`. On a work machine, which `install` recognises by its
hostname, a step in that repo replaces the one here with the same name. So work
gets its own Brewfile, Mise config and AI tools, everything else is shared, and
no work config lands in a public repo.
