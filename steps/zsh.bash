#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file config/zsh/zshrc ~/.zshrc
link_file config/zsh/zshenv ~/.zshenv
link_file config/zsh ~/.config/zsh

# The prompt lives with the shell, rather than in a step of its own, because
# it's only ever used from zsh.
link_file config/starship/starship.toml ~/.config/starship.toml
