# shellcheck shell=bash

mkdir -p ~/.config/mise
link_file "environments/$DOTFILES_ENV/mise.toml" ~/.config/mise/config.toml

if [[ $DOTFILES_ENV == work ]]; then
  if [[ ! -f ~/.local/bin/mise ]]; then
    curl https://mise.run | MISE_VERSION="v2025.8.20" sh
  fi
  export PATH=$PATH:~/.local/bin
fi

eval "$(mise activate bash)"

mise install
