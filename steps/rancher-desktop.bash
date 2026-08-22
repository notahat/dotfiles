#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file config/rancher-desktop/settings.json ~/Library/Preferences/rancher-desktop/settings.json
