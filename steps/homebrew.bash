#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

if [[ ! -f /opt/homebrew/bin/brew ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

# The home Brewfile is public, but Ferocia's lives in the private overlay
# repo instead.
if [[ $DOTFILES_ENV == home ]]; then
  brewfile="$dotfiles_dir/config/homebrew/Brewfile"
else
  brewfile="$ferocia_dir/Brewfile"
fi

brew bundle --file "$brewfile"
