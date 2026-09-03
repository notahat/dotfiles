#!/bin/bash

set -o errexit
set -o pipefail

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# This only installs Homebrew itself. The packages come later, in
# steps/brewfile.bash, because on a Ferocia machine the Brewfile lives in the
# private overlay repo, and cloning that needs git, which the Homebrew
# installer brings in with the Xcode Command Line Tools, and the 1Password SSH
# agent, which steps/onepassword.bash installs with brew.

if [[ -f /opt/homebrew/bin/brew ]]; then
  echo "Homebrew is already installed, skipping."
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
