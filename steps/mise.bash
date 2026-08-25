#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# The home mise.toml is public, but Ferocia's lives in the private overlay
# repo instead.
if [[ $DOTFILES_ENV == home ]]; then
  link_file environments/home/mise.toml ~/.config/mise/config.toml
else
  link_ferocia_file mise.toml ~/.config/mise/config.toml
fi

# Ferocia machines have no Homebrew, so mise installs itself into
# ~/.local/bin, which install puts on the PATH.
if [[ $DOTFILES_ENV == ferocia && ! -f ~/.local/bin/mise ]]; then
  curl https://mise.run | MISE_VERSION="v2025.8.20" sh
fi

eval "$(mise activate bash)"

mise install
