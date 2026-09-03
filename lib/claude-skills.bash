# shellcheck shell=bash

# The Claude skills borrowed from other people's public repos, and how to
# install and upgrade them. They're pulled from upstream rather than committed
# here, so this repo isn't redistributing other people's work. They live in
# ~/.claude/skills and never touch this repo.
#
# This is shared by steps/claude.bash, which installs whatever's missing, and
# by upgrade, which brings everything up to date. It expects lib/dotfiles.bash
# to have been sourced first.

skills_dir=~/.claude/skills

# Each entry is "kind name url". The kind is fetch, for a skill that's a lone
# SKILL.md, or clone, for one that's a repo in its own right. Skills with
# files alongside SKILL.md need cloning, as fetching would leave the files
# that SKILL.md refers to behind.
borrowed_skills=(
  # doc-coauthoring, from Anthropic's skills repo. Fetched from source rather
  # than vendored, as the upstream folder carries no explicit license.
  # https://github.com/anthropics/skills/tree/main/skills/doc-coauthoring
  "fetch doc-coauthoring https://raw.githubusercontent.com/anthropics/skills/main/skills/doc-coauthoring/SKILL.md"

  # stop-slop, by Hardik Pandya, MIT licensed.
  # https://github.com/hardikpandya/stop-slop
  "clone stop-slop https://github.com/hardikpandya/stop-slop.git"
)

# Installs any borrowed skill that's missing, and leaves the ones already
# there as they are. Bringing in newer versions is upgrade's job.
function install_borrowed_skills {
  local entry kind name url

  for entry in "${borrowed_skills[@]}"; do
    read -r kind name url <<< "$entry"

    if [[ -e $skills_dir/$name ]]; then
      echo "Skill $name is already installed, skipping."
    else
      install_skill "$kind" "$name" "$url"
    fi
  done
}

# Brings every borrowed skill up to date, installing any that are missing.
function upgrade_borrowed_skills {
  local entry kind name url

  for entry in "${borrowed_skills[@]}"; do
    read -r kind name url <<< "$entry"
    upgrade_skill "$kind" "$name" "$url"
  done
}

# Installs one borrowed skill that isn't there yet.
function install_skill {
  local kind=$1 name=$2 url=$3

  case $kind in
    fetch) fetch_skill "$name" "$url" ;;
    clone) clone_skill "$name" "$url" ;;
    *) fail_unknown_kind "$kind" "$name" ;;
  esac
}

# Brings one borrowed skill up to date. A fetched skill is a single file, so
# fetching it again is the upgrade. A cloned one is pulled, or cloned if it
# hasn't been yet.
function upgrade_skill {
  local kind=$1 name=$2 url=$3

  case $kind in
    fetch) fetch_skill "$name" "$url" ;;
    clone)
      if [[ -d $skills_dir/$name/.git ]]; then
        pull_skill "$name" "$url"
      else
        clone_skill "$name" "$url"
      fi
      ;;
    *) fail_unknown_kind "$kind" "$name" ;;
  esac
}

# Complains about a typo in the borrowed_skills list and stops, so it's
# noticed rather than the skill quietly going uninstalled.
function fail_unknown_kind {
  echo_red "Skill $2 has unknown kind \"$1\". (Fix it in lib/claude-skills.bash.)" >&2
  return 1
}

# Downloads a skill that's a lone SKILL.md, replacing whatever was there.
function fetch_skill {
  local name=$1 url=$2
  local dest=$skills_dir/$name

  mkdir -p "$dest"
  if curl -fsSL "$url" -o "$dest/SKILL.md"; then
    echo "Fetched skill $name."
  else
    echo_red "Couldn't fetch skill $name, skipping. ($url)"
  fi
}

# Clones a skill that's a repo in its own right, refusing to clobber anything
# already in the way.
function clone_skill {
  local name=$1 url=$2
  local dest=$skills_dir/$name

  if [[ -e $dest ]]; then
    echo_red "$dest is in the way and isn't a clone, skipping. (Check it.)"
  elif git clone --quiet --depth 1 "$url" "$dest"; then
    echo "Cloned skill $name."
  else
    echo_red "Couldn't clone skill $name, skipping. ($url)"
  fi
}

# Pulls the latest version of a skill that clone_skill has already cloned.
function pull_skill {
  local name=$1 url=$2
  local dest=$skills_dir/$name

  if git -C "$dest" pull --quiet --ff-only; then
    echo "Updated skill $name."
  else
    echo_red "Couldn't update skill $name, leaving it as it is. ($url)"
  fi
}
