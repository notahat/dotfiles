#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# settings.json holds the theme and footer layout Copilot reads, as opposed
# to config.json, which Copilot rewrites itself and we deliberately don't
# manage. copilot-instructions.md and the work-specific bits of
# settings.json (hooks, plugin marketplaces) live in the private Ferocia
# overlay repo, not here.
#
# agent-instructions.md is shared with Gemini (see steps/gemini.bash), so it
# lives at the top level of the overlay repo rather than under copilot/.
link_ferocia_file agent-instructions.md ~/.copilot/copilot-instructions.md
link_ferocia_file copilot/settings.json ~/.copilot/settings.json
