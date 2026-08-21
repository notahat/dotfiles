# shellcheck shell=bash

# Coloured terminal output, shared by the install and upgrade scripts.
#
# The step scripts in steps/ use these too. That works because install sources
# the steps rather than executing them, so they inherit whatever install has
# already defined.

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
