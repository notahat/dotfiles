#!/bin/bash

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# Link files one at a time. The app rewrites most of ~/.config/herdr-app on
# every start, including its own themes, layouts and mods, and keeps its state
# there too.
link_file config/herdr-app/settings.json ~/.config/herdr-app/settings.json
link_file config/herdr-app/themes/tomorrow-night.json ~/.config/herdr-app/themes/tomorrow-night.json
