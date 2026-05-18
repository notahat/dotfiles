#!/bin/bash

# Skip the notification when Ghostty is already the frontmost app — if the
# user is looking at the terminal, they don't need a popup.
frontmost=$(lsappinfo info -only bundleid "$(lsappinfo front)")
if [[ "$frontmost" == *com.mitchellh.ghostty* ]]; then
  exit 0
fi

input=$(cat)
message=$(jq -r '.message // "Waiting for input"' <<<"$input")
terminal-notifier \
  -title "Claude Code" \
  -message "$message" \
  -sound Glass \
  -activate com.mitchellh.ghostty
