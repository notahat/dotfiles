#!/bin/bash

set -o errexit
set -o pipefail

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# The home Mise config is public, but Ferocia's lives in the private overlay
# repo instead.
if [[ $DOTFILES_ENV == home ]]; then
  link_file config/mise/config.toml ~/.config/mise/config.toml
else
  link_ferocia_file mise.toml ~/.config/mise/config.toml
fi

# Mise doesn't come from Homebrew on Ferocia machines, so this installs it
# directly, into ~/.local/bin, which install puts on the PATH.
#
# -f matters on a URL we pipe into a shell: without it curl prints the error
# page and still exits 0, so an outage would feed HTML to sh.
if [[ $DOTFILES_ENV == ferocia && ! -f ~/.local/bin/mise ]]; then
  curl -fsSL https://mise.run | MISE_VERSION="v2025.8.20" sh
fi

eval "$(mise activate bash)"

mise install
