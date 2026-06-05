# shellcheck shell=bash

mkdir -p ~/.claude
link_file config/claude/CLAUDE.md ~/.claude/CLAUDE.md
link_file config/claude/settings.json ~/.claude/settings.json
link_file config/claude/statusline.sh ~/.claude/statusline.sh
link_file config/claude/skills ~/.claude/skills
link_file config/claude/hooks ~/.claude/hooks

# Fetch a borrowed skill's SKILL.md from a public GitHub repo into our skills
# directory. We pull these from upstream rather than committing copies, so we're
# not redistributing other people's work. They're gitignored in this repo.
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

# grill-me, by Matt Pocock (MIT).
# https://github.com/mattpocock/skills/tree/main/skills/productivity/grill-me
fetch_skill grill-me \
  https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/grill-me/SKILL.md
