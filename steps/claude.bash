#!/bin/bash

set -o errexit
set -o pipefail

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"
# shellcheck source=../lib/claude-skills.bash
source "$(dirname "$0")/../lib/claude-skills.bash"

link_file config/claude/CLAUDE.md ~/.claude/CLAUDE.md
link_file config/claude/settings.json ~/.claude/settings.json
link_file config/claude/statusline.sh ~/.claude/statusline.sh

# Link our skills individually, rather than linking the directory they live in,
# so that skills installed by Claude and by other tools land in ~/.claude
# instead of in this repo.
#
# nullglob so that removing the last skill doesn't leave the loop running once
# over the unexpanded pattern, which would try to link a directory called "*".
shopt -s nullglob
for skill_dir in "$dotfiles_dir"/config/claude/skills/*/; do
  skill=$(basename "$skill_dir")
  link_file "config/claude/skills/$skill" ~/.claude/skills/"$skill"
done
shopt -u nullglob

# Borrowed skills only get fetched here if they're missing. Refreshing the
# ones already installed is what upgrade does, so that install stays a
# no-op on a machine that's already set up.
install_borrowed_skills
