#!/bin/bash

set -o errexit
set -o pipefail

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# Link the config file on its own, rather than the directory around it. Herdr
# keeps its socket, logs, and session state in ~/.config/herdr as well, and none
# of that belongs in this repo.
link_file config/herdr/config.toml ~/.config/herdr/config.toml
