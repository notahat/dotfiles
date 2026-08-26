#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file config/zed/keymap.json ~/.config/zed/keymap.json
link_file config/zed/settings.json ~/.config/zed/settings.json
link_ferocia_file agent-instructions.md ~/.config/zed/AGENTS.md
