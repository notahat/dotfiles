#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

link_file config/claude/CLAUDE.md ~/.claude/CLAUDE.md
link_file config/claude/settings.json ~/.claude/settings.json
link_file config/claude/statusline.sh ~/.claude/statusline.sh

# Link our skills and hooks individually, rather than linking the directories
# they live in, so that skills and hooks installed by Claude and by other tools
# land in ~/.claude instead of in this repo.
mkdir -p ~/.claude/hooks
link_file config/claude/skills/diataxis ~/.claude/skills/diataxis
link_file config/claude/skills/dune-watcher ~/.claude/skills/dune-watcher
link_file config/claude/skills/install-project-template ~/.claude/skills/install-project-template


# Fetch a borrowed skill's SKILL.md from a public GitHub repo into our skills
# directory. We pull these from upstream rather than committing copies, so we're
# not redistributing other people's work. They live in ~/.claude/skills and
# never touch this repo.
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

# doc-coauthoring, from Anthropic's skills repo. Fetched from source rather than
# vendored, as the upstream folder carries no explicit license.
# https://github.com/anthropics/skills/tree/main/skills/doc-coauthoring
fetch_skill doc-coauthoring \
  https://raw.githubusercontent.com/anthropics/skills/main/skills/doc-coauthoring/SKILL.md
