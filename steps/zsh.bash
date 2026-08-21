# shellcheck shell=bash

link_file config/zsh/zshrc ~/.zshrc
link_file config/zsh/zshenv ~/.zshenv
link_file config/zsh ~/.config/zsh

# We use submodules for zsh plugins, so make sure we've got 'em. Needs -C, as
# install might have been run from outside the repo. install sets dotfiles_dir
# before it sources this step.
# shellcheck disable=SC2154
git -C "$dotfiles_dir" submodule update --init --depth 1
