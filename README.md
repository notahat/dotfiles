# Pete's dotfiles

I've been refining these dotfiles since 2010. They do 80% of the work of
setting up a Mac the way I like it:

```sh
xcode-select --install
git clone https://github.com/notahat/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
DOTFILES_ENV=home ./install
```

I keep them lean. Anything I stop using I delete, so what's left is what I run
every day.

## Highlights worth stealing

- **A tiny install you can actually read.** `./install` runs plain-bash steps
  from [`steps/`](steps). It symlinks config into place and is idempotent, so I
  re-run it and it never rots. If a config file already exists, it warns and
  skips rather than clobbering it.
- **A clear rule for Homebrew vs. Mise.** [Homebrew](https://brew.sh) installs
  anything I always want at the latest version (apps, CLI tools, even Mac App
  Store apps). [Mise](https://mise.jdx.dev) manages anything I need pinned to a
  particular version, like language runtimes.
- **Zsh that starts in <100ms.** A [Starship](https://starship.rs) prompt,
  fzf-tab completion, and syntax highlighting, wired up by hand in
  [`config/zsh`](config/zsh), with none of the [Oh My Zsh](https://ohmyz.sh)
  bloat.
- **Neovim, under 100ms too.** Modern IDE features (LSP, Treesitter, fuzzy
  finding) with a minimal UI, so the code stays front-and-centre. It's
  commented throughout and has [its own README](config/nvim).
- **One command to update everything.** `./upgrade` bumps Homebrew packages,
  Mise tools, and Neovim plugins.
- **A version-controlled Claude Code setup.** Custom skills, settings, and a
  statusline live in [`config/claude`](config/claude).

## How it works

`./install` runs the steps in [`steps/`](steps), each a small bash script that
installs a tool and symlinks its config. Run them all, or one at a time:

```sh
./install         # everything
./install zsh     # just the zsh step
./install -h      # usage, and the list of steps
```

The pieces:

- [`config/`](config): every config file, symlinked into `~` and `~/.config`
  by the steps. Edit it in place here.
- [`environments/`](environments): the `Brewfile` and `mise.toml` for my home
  machine. Work machines use a different pair. See below.
- [`project-templates/`](project-templates): drop-in editor and tooling config
  for new Rails and Vite projects.

### Work machines

I use these dotfiles at work too, where I need a few extra tools and some config
I'd rather not publish. Rather than fork, I keep the work-only bits in a second,
private repo and set `DOTFILES_ENV=ferocia` (my employer) on those machines.
`steps/ferocia.bash` clones that repo to `~/.dotfiles-ferocia`, and the other
steps pull config out of it with `link_ferocia_file`. So I run the same dotfiles
on both machines, and no work config lands in a public repo.

## Borrow freely

Take whatever's useful, whether a whole config, a single alias, or an idea.
Everything here is [MIT licensed](LICENSE).
