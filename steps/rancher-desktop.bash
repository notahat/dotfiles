#!/bin/bash

set -o errexit
set -o pipefail

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# Rancher Desktop is only installed on Ferocia machines (OrbStack replaces it
# at home), so its settings live in the private overlay repo rather than
# here. link_ferocia_file does nothing when that repo isn't cloned, so this
# is a no-op on a home machine.
link_ferocia_file rancher-desktop/settings.json ~/Library/Preferences/rancher-desktop/settings.json
