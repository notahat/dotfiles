#!/bin/bash

set -o errexit
set -o pipefail

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file config/claude/CLAUDE.md ~/.claude/CLAUDE.md
link_file config/claude/settings.json ~/.claude/settings.json
link_file config/claude/statusline.sh ~/.claude/statusline.sh

# Link our skills individually, rather than linking the directory they live in,
# so that skills installed by Claude and by other tools land in ~/.claude
# instead of in this repo.
for skill_dir in "$dotfiles_dir"/config/claude/skills/*/; do
  skill=$(basename "$skill_dir")
  link_file "config/claude/skills/$skill" ~/.claude/skills/"$skill"
done

# The two functions below bring in borrowed skills from other people's public
# repos. We pull these from upstream rather than committing copies, so we're
# not redistributing other people's work. They live in ~/.claude/skills and
# never touch this repo.

# Fetch a borrowed skill that's a lone SKILL.md.
function fetch_skill {
  local name=$1 url=$2
  local dest=~/.claude/skills/$name
  mkdir -p "$dest"
  if curl -fsSL "$url" -o "$dest/SKILL.md"; then
    echo "Fetched skill $name."
  else
    echo_red "Couldn't fetch skill $name, skipping. ($url)"
  fi
}

# Clone, or update, a borrowed skill that's a repo in its own right. Skills
# with files alongside SKILL.md need this, as fetch_skill would leave the
# files that SKILL.md refers to behind.
function clone_skill {
  local name=$1 url=$2
  local dest=~/.claude/skills/$name

  if [[ -d $dest/.git ]]; then
    if git -C "$dest" pull --quiet --ff-only; then
      echo "Updated skill $name."
    else
      echo_red "Couldn't update skill $name, leaving it as it is. ($url)"
    fi
  elif [[ -e $dest ]]; then
    echo_red "$dest is in the way and isn't a clone, skipping. (Check it.)"
  elif git clone --quiet --depth 1 "$url" "$dest"; then
    echo "Cloned skill $name."
  else
    echo_red "Couldn't clone skill $name, skipping. ($url)"
  fi
}

# doc-coauthoring, from Anthropic's skills repo. Fetched from source rather than
# vendored, as the upstream folder carries no explicit license.
# https://github.com/anthropics/skills/tree/main/skills/doc-coauthoring
fetch_skill doc-coauthoring \
  https://raw.githubusercontent.com/anthropics/skills/main/skills/doc-coauthoring/SKILL.md

# stop-slop, by Hardik Pandya, MIT licensed. Cloned rather than fetched, as its
# SKILL.md leans on the reference files beside it.
# https://github.com/hardikpandya/stop-slop
clone_skill stop-slop https://github.com/hardikpandya/stop-slop.git
