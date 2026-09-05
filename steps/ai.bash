#!/bin/bash

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file config/claude/CLAUDE.md ~/.claude/CLAUDE.md
link_file config/claude/settings.json ~/.claude/settings.json
link_file config/claude/statusline.sh ~/.claude/statusline.sh

# Links a skill kept in this repo into ~/.claude/skills.
function install_local_skill {
  local skill=$1
  link_file "config/claude/skills/$skill" ~/.claude/skills/"$skill"
}

# Installs a skill from the internet.
#
# The skills CLI has no quiet mode and narrates every install at length, so
# its output is held back unless the install fails.
function install_remote_skill {
  local name=$1 skill=$2 log
  if [[ -e "$HOME/.claude/skills/$name" ]]; then
    echo "$name skill is already installed, skipping."
    return
  fi

  log=$(mktemp)
  if ! DO_NOT_TRACK=1 npx --yes skills add "$skill" --global --agent claude-code --yes >"$log" 2>&1; then
    cat "$log"
    rm -f "$log"
    echo_red "Installing $name skill failed."
    return 1
  fi
  rm -f "$log"
  echo "Installed $name skill."
}

install_local_skill diataxis
install_local_skill dune-watcher
install_local_skill install-project-template

install_remote_skill doc-coauthoring "https://github.com/anthropics/skills/tree/main/skills/doc-coauthoring"
install_remote_skill stop-slop "hardikpandya/stop-slop"
