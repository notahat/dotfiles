# shellcheck shell=bash

if [[ ! -f /opt/homebrew/bin/brew ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

# install sets dotfiles_dir before it sources this step.
# shellcheck disable=SC2154
brew bundle --file "$dotfiles_dir/environments/$DOTFILES_ENV/Brewfile"
