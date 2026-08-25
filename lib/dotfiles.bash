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

# Same as link_file, but for the private, Ferocia-only overlay repo. Silently
# does nothing if that repo hasn't been cloned (e.g. on a home machine), so
# steps can call this unconditionally without checking DOTFILES_ENV
# themselves.
function link_ferocia_file {
  if [[ ! -d $ferocia_dir ]]; then
    return
  fi

  mkdir -p "$(dirname "$2")"

  if [[ -L "$2" ]]; then
    echo "$2 is already linked, skipping."
  elif [[ -e "$2" ]]; then
    echo_red "$2 already exists, skipping. (You might not want this, so check the file.)"
  else
    ln -s "$ferocia_dir/$1" "$2"
    echo "Linked $2"
  fi
}

# Fetches or updates a borrowed skill into both Copilot's and Gemini's skills
# directories, so it only has to be downloaded once. Mirrors claude.bash's
# fetch_skill/clone_skill, but for the two tools that share skills (see
# steps/copilot.bash and steps/gemini.bash). Used by the private Ferocia
# overlay repo to install work-specific skills, not by this repo directly.

# Fetch a borrowed skill that's a lone SKILL.md.
function fetch_agent_skill {
  local name=$1 url=$2

  for dest in ~/.copilot/skills/"$name" ~/.gemini/skills/"$name"; do
    mkdir -p "$dest"
    if curl -fsSL "$url" -o "$dest/SKILL.md"; then
      echo "Fetched skill $name to $dest."
    else
      echo_red "Couldn't fetch skill $name to $dest, skipping. ($url)"
    fi
  done
}

# Clone, or update, a borrowed skill that's a repo in its own right. Skills
# with files alongside SKILL.md need this, as fetch_agent_skill would leave
# the files that SKILL.md refers to behind. Clones once, then symlinks the
# second tool's copy to it, so there's still only one clone to keep updated.
function clone_agent_skill {
  local name=$1 url=$2
  local primary=~/.copilot/skills/$name
  local secondary=~/.gemini/skills/$name

  if [[ -d $primary/.git ]]; then
    if git -C "$primary" pull --quiet --ff-only; then
      echo "Updated skill $name."
    else
      echo_red "Couldn't update skill $name, leaving it as it is. ($url)"
    fi
  elif [[ -e $primary ]]; then
    echo_red "$primary is in the way and isn't a clone, skipping. (Check it.)"
  elif git clone --quiet --depth 1 "$url" "$primary"; then
    echo "Cloned skill $name."
  else
    echo_red "Couldn't clone skill $name, skipping. ($url)"
  fi

  mkdir -p "$(dirname "$secondary")"
  if [[ -L $secondary ]]; then
    : # Already linked, nothing to do.
  elif [[ -e $secondary ]]; then
    echo_red "$secondary is in the way and isn't a link, skipping. (Check it.)"
  else
    ln -s "$primary" "$secondary"
    echo "Linked $secondary"
  fi
}
