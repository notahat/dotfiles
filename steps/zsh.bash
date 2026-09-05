#!/bin/bash

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file config/zsh/zshrc ~/.zshrc
link_file config/zsh/zshenv ~/.zshenv
