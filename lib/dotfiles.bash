# shellcheck shell=bash

# Shared helpers for the install script and for the steps it runs.
#
# Each step is its own program, and sources this file directly. It's the only
# thing a step depends on from outside itself, which is what lets a step be
# read, and run, on its own.

# Where this repo lives, resolved to an absolute path so the steps work no
# matter which directory install was run from. BASH_SOURCE is this file rather
# than whoever sourced it, which is what makes the lookup reliable.
dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Where the private, Ferocia-only overlay repo lives, if it's present at all.
# It only exists on Ferocia machines, cloned by steps/ferocia.bash, so
# anything that uses it has to cope with it being absent (e.g. on a home
# machine, or before that step has run).
ferocia_dir="$HOME/.dotfiles-ferocia"

red="\033[31m"
green="\033[32m"
reset="\033[0;39m"

# Prints a message in red, for something the user should look at.
function echo_red {
  echo -e "${red}${1}${reset}"
}

# Prints a message in green, for progress.
function echo_green {
  echo -e "${green}${1}${reset}"
}

# Symlinks a file or directory into place, creating the parent directory if it
# needs to. Refuses to clobber anything already there.
#
# The source is an absolute path. Steps call link_file or link_ferocia_file
# below instead, which say which repo the source comes from.
function create_link {
  local source=$1 destination=$2

  mkdir -p "$(dirname "$destination")"

  if [[ -L $destination ]]; then
    check_link "$source" "$destination"
  elif [[ -e $destination ]]; then
    echo_red "$destination already exists, skipping. (You might not want this, so check the file.)"
  else
    ln -s "$source" "$destination"
    echo "Linked $destination"
  fi
}

# Reports on a link that's already in place. One pointing anywhere other than
# the file being installed is worth knowing about: it's usually left behind by
# a config file that's since been renamed or moved, in which case it's now
# dangling and whatever reads it has quietly lost its config.
#
# This compares the path the link holds rather than where it resolves to, so
# that it still says something useful about a link that's dangling.
function check_link {
  local source=$1 destination=$2 target
  target=$(readlink "$destination")

  if [[ $target == "$source" ]]; then
    echo "$destination is already linked, skipping."
  else
    echo_red "$destination links to $target, not $source. (Remove it and re-run to fix it.)"
  fi
}

# Symlinks a file or directory from this repo into place.
#
# The source is given relative to the root of this repo.
function link_file {
  create_link "$dotfiles_dir/$1" "$2"
}

# Same as link_file, but for the private, Ferocia-only overlay repo. Silently
# does nothing if that repo hasn't been cloned (e.g. on a home machine), so
# steps can call this unconditionally without checking DOTFILES_ENV
# themselves.
function link_ferocia_file {
  if [[ ! -d $ferocia_dir ]]; then
    return
  fi

  create_link "$ferocia_dir/$1" "$2"
}
