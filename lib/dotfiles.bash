# shellcheck shell=bash

# Shared helpers for the install script and for the steps it runs.
#
# Each step is its own program, and sources this file directly. It's the only
# thing a step depends on from outside itself, beyond the steps before it
# having run, which is what lets a step be read, and run, on its own.

# Make sure all the steps can find things installed with mise and homebrew.
export PATH="$HOME/.local/share/mise/shims:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Where this repo lives, resolved to an absolute path so the steps work no
# matter which directory install was run from. BASH_SOURCE is this file rather
# than whoever sourced it, which is what makes the lookup reliable.
dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Which machine this is: home, or ferocia (my employer), whose machines have
# hostnames starting fer-. Used by install, not by steps.
# shellcheck disable=SC2034
if [[ $(hostname -s) == fer-* ]]; then
  DOTFILES_ENV=ferocia
else
  DOTFILES_ENV=home
fi

# Where the private, Ferocia-only overlay repo lives. It's cloned by hand, and
# only on Ferocia machines.
# shellcheck disable=SC2034
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
# The source is an absolute path. Steps in this repo use link_file instead.
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

# Reports on a link that's already in place.
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
