#!/bin/bash

set -o errexit
set -o pipefail

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

if [[ -f /opt/homebrew/bin/brew ]]; then
  echo "Homebrew is already installed, skipping."
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

link_file config/homebrew/Brewfile ~/.homebrew/Brewfile

brew bundle --global
