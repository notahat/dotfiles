#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# Gemini's config is entirely work-specific for now, so it all comes from the
# private Ferocia overlay repo rather than from here.
link_ferocia_file gemini/settings.json ~/.gemini/settings.json
link_ferocia_file gemini/GEMINI.md ~/.gemini/GEMINI.md
