#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file config/ssh/ssh-config ~/.ssh/config

# SSH ignores a config directory that other users can get into.
chmod 700 ~/.ssh
