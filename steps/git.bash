#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file config/git/ignore ~/.config/git/ignore

# ~/.config/git/config has to stay a real file, because that's where git writes
# when you run `git config --global`. So it gets an include pointing at this
# repo's settings rather than being a symlink to them.
touch ~/.config/git/config
git config --global include.path "$dotfiles_dir/config/git/gitconfig"
