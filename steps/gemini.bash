#!/bin/bash

set -o errexit
set -o pipefail

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# Gemini's settings.json is entirely work-specific for now, so it comes from
# the private Ferocia overlay repo rather than from here. GEMINI.md is
# replaced by agent-instructions.md, shared with Copilot (see
# steps/copilot.bash).
link_ferocia_file gemini/settings.json ~/.gemini/settings.json
link_ferocia_file agent-instructions.md ~/.gemini/GEMINI.md
