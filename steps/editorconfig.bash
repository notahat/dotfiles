#!/bin/bash

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# Its own step because Neovim and Zed both read it.
link_file config/editorconfig/editorconfig ~/.editorconfig
