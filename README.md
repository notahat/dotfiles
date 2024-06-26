# Pete's dotfiles

This does 80% of the work of setting up a Mac the way I like it:

```sh
xcode-select --install
git clone git://github.com/notahat/dotfiles ~/.dotfiles
cd ~/.dotfiles
export DOTFILES_ENV=home
./install
```

I re-run this frequently (it's idempotent), which ensures I maintain it.

I remove anything I'm not using to keep it simple.

## How It Works

`./install` runs steps from the `steps` directory. You can run individual steps, or the whole set. See `./install -h` for usage.

All my config files live under `config`. These get soft-linked into place by the steps.

The `environments` directory contains separate `Brewfile`s and `mise.toml` files for my home and work machines.

[Homebrew](https://brew.sh) installs anything where I always want the latest version, including apps from the Mac App Store.

[Mise](https://mise.jdx.dev/) manages things like languages, where I want particular versions installed.
