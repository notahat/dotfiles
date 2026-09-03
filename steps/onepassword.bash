#!/bin/bash

set -o errexit
set -o pipefail

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# 1Password holds the SSH keys, so its SSH agent has to be answering before
# steps/ferocia.bash can clone the private overlay repo. That's why this
# installs the app directly rather than leaving it to the Brewfile: on a
# Ferocia machine the Brewfile is inside that overlay.
#
# Signing in and turning the agent on can't be scripted, so when the agent
# isn't there yet this says what to do and stops. Re-running install picks
# up where it left off.

# The socket 1Password's SSH agent listens on. config/ssh/config points
# IdentityAgent at the same path.
agent_socket="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

eval "$(/opt/homebrew/bin/brew shellenv)"

if [[ -d /Applications/1Password.app ]]; then
  echo "1Password is already installed, skipping."
else
  brew install --cask 1password
fi

if [[ -S $agent_socket ]]; then
  echo "1Password's SSH agent is running."
  exit 0
fi

echo_red "1Password's SSH agent isn't running yet. Finish setting it up, then re-run install:" >&2
echo >&2
echo "  1. Open 1Password and sign in." >&2
echo "  2. In Settings > Developer, turn on \"Use the SSH agent\"." >&2
echo "  3. Leave 1Password unlocked, so the agent can hand out keys." >&2
exit 1
