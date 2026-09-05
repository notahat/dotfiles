#!/bin/bash

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file config/starship/starship.toml ~/.config/starship.toml
