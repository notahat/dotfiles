#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file config/copilot/copilot-instructions.md ~/.copilot/copilot-instructions.md

# settings.json holds the theme and footer layout Copilot reads, as opposed
# to config.json, which Copilot rewrites itself and we deliberately don't
# manage. Work-specific settings (hooks, plugin marketplaces) live in the
# private Ferocia overlay repo, not here.
link_ferocia_file copilot/settings.json ~/.copilot/settings.json
