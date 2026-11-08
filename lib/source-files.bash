# shellcheck shell=bash

# The lists of files that lint and format work on, so the two scripts always
# agree. Each function prints paths relative to the repo root, ending each
# with a NUL for `xargs -0`, and must be called from the repo root.

# Prints the bash scripts. The zsh config is left out because zsh syntax
# isn't something shellcheck or shfmt can parse.
function list_shell_files() {
  printf '%s\0' install upgrade lint format format-file lib/*.bash steps/*.bash config/claude/statusline.sh
}

# Prints the JSON files git tracks, which leaves out local files like Claude
# Code's settings.local.json. Claude Code's settings.json is left out because
# Claude Code rewrites it in its own formatting, which differs from
# prettier's. Symlinks are left out too, because prettier refuses them, and
# the files they point to are in the list anyway.
function list_json_files() {
  local file
  git ls-files '*.json' '*.jsonc' ':!config/claude/settings.json' | while read -r file; do
    if [[ ! -L ${file} ]]; then
      printf '%s\0' "${file}"
    fi
  done
}
