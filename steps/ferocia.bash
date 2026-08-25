#!/bin/bash

set -o errexit

# shellcheck source=../lib/dotfiles.bash
source "$(dirname "$0")/../lib/dotfiles.bash"

# The private, Ferocia-only overlay repo. It holds things too specific to
# this job to belong in the public dotfiles repo (API keys' neighbours,
# internal tool config, that kind of thing), and is pulled down here so
# later steps can link files out of it. It only exists on work machines, so
# other steps use link_ferocia_file, which copes with it being absent.
#
# This has to run before any step that calls link_ferocia_file.

if [[ $DOTFILES_ENV != work ]]; then
  echo "Not a work machine, skipping."
  exit 0
fi

if [[ -d $ferocia_dir ]]; then
  git -C "$ferocia_dir" pull --ff-only
else
  git clone git@github.com:notahat/dotfiles-ferocia.git "$ferocia_dir"
fi
