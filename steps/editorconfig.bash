#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# EditorConfig gets a step to itself because no single editor owns it. Neovim
# and Zed both read it, so putting the link in either one's step would be
# arbitrary.
link_file config/editorconfig/editorconfig ~/.editorconfig
