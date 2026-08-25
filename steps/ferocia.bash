#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# The private, Ferocia-only overlay repo. It holds things too specific to
# this job to belong in the public dotfiles repo (API keys' neighbours,
# internal tool config, that kind of thing), and is pulled down here so
# later steps can link files out of it. It only exists when
# DOTFILES_ENV=ferocia, so other steps use link_ferocia_file, which copes
# with it being absent.
#
# This has to run before any step that calls link_ferocia_file.

if [[ $DOTFILES_ENV != ferocia ]]; then
  echo "Not a Ferocia machine, skipping."
  exit 0
fi

if [[ -d $ferocia_dir ]]; then
  git -C "$ferocia_dir" pull --ff-only
else
  git clone git@github.com:notahat/dotfiles-ferocia.git "$ferocia_dir"
fi

# The overlay repo can bring its own script to install work-specific skills,
# using fetch_agent_skill/clone_agent_skill (defined in lib/dotfiles.bash) to
# install them for both Copilot and Gemini. It's optional, so this copes with
# it being absent.
if [[ -f "$ferocia_dir/skills.bash" ]]; then
  # shellcheck source=/dev/null
  source "$ferocia_dir/skills.bash"
fi
