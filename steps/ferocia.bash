#!/bin/bash

set -o errexit
set -o pipefail

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# The private, Ferocia-only overlay repo. It holds things too specific to
# this job to belong in the public dotfiles repo (API keys' neighbours,
# internal tool config, that kind of thing), and is pulled down here so
# later steps can link files out of it. It only exists when
# DOTFILES_ENV=ferocia, so other steps use link_ferocia_file, which copes
# with it being absent.
#
# This has to run before any step that calls link_ferocia_file, and after
# the ones that make the clone possible: homebrew, for git; onepassword,
# for the SSH agent that holds the key; and ssh, for the config that points
# at that agent.

if [[ $DOTFILES_ENV != ferocia ]]; then
  echo "Not a Ferocia machine, skipping."
  exit 0
fi

if [[ -d $ferocia_dir ]]; then
  git -C "$ferocia_dir" pull --ff-only
else
  git clone git@github.com:notahat/dotfiles-ferocia.git "$ferocia_dir"
fi

# The overlay repo can bring its own script defining work-specific skills
# for both Copilot and Gemini (it defines install_agent_skills/
# upgrade_agent_skills, the same convention as lib/claude-skills.bash). It's
# optional, so this copes with it being absent.
#
# Only missing skills get installed here. Refreshing the ones already
# installed is what upgrade does, so that install stays a no-op on a machine
# that's already set up.
if [[ -f "$ferocia_dir/skills.bash" ]]; then
  # shellcheck source=/dev/null
  source "$ferocia_dir/skills.bash"
  install_agent_skills
fi
