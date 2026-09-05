# CLAUDE.md

Public dotfiles for two machines. The install script symlinks everything in
`config/` into `~`, so the file you edit here is the file your machine reads.
No build step, nothing to deploy.

## Invariants

- **Re-running is safe.** Every step has to be idempotent. `./install` runs on
  a working machine as often as on a new one.
- **`create_link` never overwrites.** It warns about whatever already sits in
  the destination, including a link pointing somewhere unexpected. Leave it
  warning. Don't teach it to relink: that warning usually means you renamed a
  config file and left its old link behind, which is worth seeing.
- **This repo is public.** Nothing work-specific or secret goes in it. The
  Ferocia overlay exists to hold that.
- **Borrowed skills are installed, never committed.** `steps/ai.bash` pulls
  them from upstream with `npx skills`, so this repo doesn't redistribute
  other people's work. The step only installs the ones that are missing;
  `upgrade` brings them up to date, using the sources the CLI records in
  `~/.agents/.skill-lock.json`.
- **It has to run on a fresh machine.** `#!/bin/bash` is deliberate: the only
  bash there is macOS's 3.2, and Homebrew's isn't installed yet. No bash 4+
  syntax, and don't switch to `/usr/bin/env bash`.
- **Steps run standalone.** A step may depend on the files in `lib/` and
  nothing else outside itself.

## Link the narrowest thing

Link individual files, not the directory around them, wherever a tool keeps its
own state next to its config. `steps/herdr.bash` links one config file and
leaves the sockets and logs alone. `steps/ai.bash` links skills one at a
time, so the ones Claude installs don't land in this repo.

Some tools rewrite their own config, and those you don't link at all.
`steps/git.bash` leaves `~/.config/git/config` real and points at this repo
with `include.path`.

## Layout

One directory per tool under `config/`. Name the file for where it lands, not
for the tool, so the step that links it reads as a straight move:
`config/ssh/config` becomes `~/.ssh/config`, and `config/zsh/zshrc` becomes
`~/.zshrc`.

No installed config lives at the repo root. The root holds this repo's own
tooling, like `.shellcheckrc` and `.zed/`, plus symlinks back into `config/`
for tools that insist on finding their config at the root of whatever tree you
open them on. `.editorconfig` and `.luarc.jsonc` are both that.

## Adding or changing a step

Before editing `install`, `upgrade`, or anything in `lib/` or `steps/`, read
`docs/shell-style.md`.

One step per tool, named after the tool. It needs the file in `steps/` and an
entry in the `STEPS` array in `install`. That array sets the run order, so
don't sort it. `homebrew` installs `mise`, and `mise` installs the node that
`ai` needs. `ai` is the exception to naming steps after tools: it's the slot
for whichever AI tools a machine gets, which differ entirely between home
and work.

Start from an existing step. Give `curl -fsSL` to anything you pipe into a
shell, because bare curl exits 0 on an HTTP error and hands the error page to
`sh`.

## Environments

`DOTFILES_ENV` is `home` or `ferocia`. `install` works it out from the
hostname, and nothing else reads it.

Every step in this repo is a home step. The private `dotfiles-ferocia` repo,
cloned by hand to `~/.dotfiles-ferocia`, has its own `steps/` directory, and
on a Ferocia machine a step there replaces the one here with the same name.
That's the whole mechanism: there's no branching on `DOTFILES_ENV` inside
steps, and nothing here links files out of the overlay. A step the overlay
doesn't override runs as it would at home, so `install` refuses to run as
`ferocia` without the overlay present.

## Verification

Run the step you changed, as `./install zsh` or `./steps/zsh.bash`. Then run
shellcheck from the repo root, so `.shellcheckrc` applies. It passes on this
tree:

    shellcheck install upgrade lib/*.bash steps/*.bash config/claude/statusline.sh

Don't run the overlay's steps on a home machine: each one links work config
into `~`. From `~/.dotfiles-ferocia`, run shellcheck over `lib/*.bash` and
`steps/*.bash` and check they parse with `bash -n`, and say that's all you
did.
