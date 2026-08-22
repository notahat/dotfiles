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

# Symlinks a file or directory from this repo into place, creating the parent
# directory if it needs to. Refuses to clobber anything already there.
#
# The source is given relative to the root of this repo.
function link_file {
  mkdir -p "$(dirname "$2")"

  if [[ -L "$2" ]]; then
    echo "$2 is already linked, skipping."
  elif [[ -e "$2" ]]; then
    echo_red "$2 already exists, skipping. (You might not want this, so check the file.)"
  else
    ln -s "$dotfiles_dir/$1" "$2"
    echo "Linked $2"
  fi
}
