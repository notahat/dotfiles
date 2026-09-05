#!/bin/bash

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# Don't show recents in the dock. The Dock only picks the setting up when it
# restarts, so it's only restarted when the setting actually changes. A fresh
# machine has no such key, which reads back as empty here.
if [[ $(defaults read com.apple.dock show-recents 2>/dev/null) != 0 ]]; then
  defaults write com.apple.dock show-recents -bool false
  killall Dock
  echo "Turned off Dock recents."
else
  echo "Dock recents are already off, skipping."
fi

# Don't have the fn key open the emoji picker.
# This doesn't seem to stick until a logout. :(
if [[ $(defaults read com.apple.HIToolbox AppleFnUsageType 2>/dev/null) != 0 ]]; then
  defaults write com.apple.HIToolbox AppleFnUsageType -int 0
  echo "Set the fn key to do nothing."
else
  echo "The fn key already does nothing, skipping."
fi

# Turn on filevault.
if ! fdesetup status | grep -qE "FileVault is (On|Off, but will be enabled after the next restart)."; then
  sudo fdesetup enable -user "$USER" | tee ~/Desktop/"FileVault Recovery Key.txt"
  echo "Turned on FileVault. The recovery key is on the Desktop."
else
  echo "FileVault is already on, skipping."
fi

# Turn on the firewall. Reading the state doesn't need sudo, so a re-run on a
# configured machine doesn't ask for a password. State 2 blocks all incoming
# connections and also reports as enabled, so the check is for "disabled"
# rather than for a particular state number.
firewall=/usr/libexec/ApplicationFirewall/socketfilterfw
if "$firewall" --getglobalstate | grep -q "Firewall is disabled"; then
  sudo "$firewall" --setglobalstate on
  echo "Turned on the firewall."
else
  echo "Firewall is already on, skipping."
fi
