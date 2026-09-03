#!/bin/bash

set -o errexit
set -o pipefail

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# Installs everything in the Brewfile. It's a step of its own, apart from
# steps/homebrew.bash, because on a Ferocia machine the Brewfile lives in the
# private overlay repo, so this can't run until steps/ferocia.bash has cloned
# it. Homebrew itself has to exist well before that.

eval "$(/opt/homebrew/bin/brew shellenv)"

# The home Brewfile is public, but Ferocia's lives in the private overlay
# repo instead.
if [[ $DOTFILES_ENV == home ]]; then
  brewfile="$dotfiles_dir/config/homebrew/Brewfile"
else
  brewfile="$ferocia_dir/Brewfile"
fi

brew bundle --file "$brewfile"
