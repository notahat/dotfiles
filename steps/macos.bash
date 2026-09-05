#!/bin/bash

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# Don't show recents in the dock.
defaults write com.apple.dock show-recents -boolean FALSE
killall Dock

# Don't have the fn key open the emoji picker.
# This doesn't seem to stick until a logout. :(
defaults write com.apple.HIToolbox AppleFnUsageType -int 0

# Turn on filevault.
if ! fdesetup status | grep -qE "FileVault is (On|Off, but will be enabled after the next restart)."; then
  sudo fdesetup enable -user "$USER" | tee ~/Desktop/"FileVault Recovery Key.txt"
fi

# Turn on the firewall.
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
