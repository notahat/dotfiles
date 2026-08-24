#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# We deliberately don't manage ~/.copilot/config.json. Copilot rewrites that
# file itself to track trusted folders, login state, and recently used models,
# and says so in its own header. settings.json is the half meant for us.
link_file config/copilot/settings.json ~/.copilot/settings.json
link_file config/copilot/copilot-instructions.md ~/.copilot/copilot-instructions.md
