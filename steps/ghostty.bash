#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file config/ghostty ~/.config/ghostty
