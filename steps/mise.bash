# shellcheck shell=bash

mkdir -p ~/.config/mise
link_file "environments/$DOTFILES_ENV/mise.toml" ~/.config/mise/config.toml

if [[ $DOTFILES_ENV == work ]]; then
  if [[ ! -f ~/.local/bin/mise ]]; then
    curl https://mise.run | MISE_VERSION="v2024.12.7" sh
  fi
fi

eval "$(mise activate bash)"

mise install
