#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file config/zsh/zshrc ~/.zshrc
link_file config/zsh/zshenv ~/.zshenv

# Work-specific environment and shell config lives in the private Ferocia
# overlay repo, and config/zsh/zshenv and config/zsh/zshrc source these from
# here if they exist.
link_ferocia_file zshenv ~/.zshenv-ferocia
link_ferocia_file zshrc ~/.zshrc-ferocia

# The prompt lives with the shell, rather than in a step of its own, because
# it's only ever used from zsh.
link_file config/starship/starship.toml ~/.config/starship.toml
