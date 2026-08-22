#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file "environments/$DOTFILES_ENV/mise.toml" ~/.config/mise/config.toml

# Work machines have no Homebrew, so mise installs itself into ~/.local/bin,
# which install puts on the PATH.
if [[ $DOTFILES_ENV == work && ! -f ~/.local/bin/mise ]]; then
  curl https://mise.run | MISE_VERSION="v2025.8.20" sh
fi

eval "$(mise activate bash)"

mise install
