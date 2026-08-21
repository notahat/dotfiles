# shellcheck shell=bash

link_file config/ssh/ssh-config ~/.ssh/config

# SSH ignores a config directory that other users can get into.
chmod 700 ~/.ssh
