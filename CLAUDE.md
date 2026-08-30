# CLAUDE.md

## Verification

After making changes, run the relevant step script from `steps/` directly to verify it applies cleanly (e.g., `./install zsh`). Run `./install` for a full idempotent re-run across all steps.

## Structure

Config files live in `config/` and are symlinked into `~/` and `~/.config/` by the install script. Edit them in place in the repo.

## Environments

`DOTFILES_ENV` controls home vs Ferocia configuration and is auto-detected from hostname in `config/zsh/zshenv`. The home Brewfile and Mise config live in `config/homebrew/` and `config/mise/`; Ferocia's equivalents live in the private `dotfiles-ferocia` repo, pulled down to `~/.dotfiles-ferocia` by `steps/ferocia.bash` and linked out with `link_ferocia_file`.
