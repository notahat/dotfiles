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
- **It has to run on a fresh machine.** `#!/bin/bash` is deliberate: the only
  bash there is macOS's 3.2, and Homebrew's isn't installed yet. No bash 4+
  syntax, and don't switch to `/usr/bin/env bash`.
- **Steps run standalone.** A step may depend on the files in `lib/` and
  nothing else outside itself. In particular, no step reads `DOTFILES_ENV`.
  Only `install` does, to pick which repo a step comes from.

## Link the narrowest thing

Link individual files, not the directory around them, wherever a tool keeps its
own state next to its config. `steps/herdr.bash` links one config file and
leaves the sockets and logs alone. `steps/ai.bash` links skills one at a
time, so the ones Claude installs don't land in this repo.

Some tools rewrite their own config, and those you don't link at all.
`steps/git.bash` leaves `~/.config/git/config` real and points at this repo
with `include.path`. Nothing here touches Copilot's `config.json`.

`steps/ai.bash` installs borrowed skills from upstream with `npx skills`
instead of committing copies, so this repo doesn't redistribute other people's
work. Keep it that way. The step only installs the ones that are missing;
`upgrade` is what brings them up to date, using the sources the CLI records in
`~/.agents/.skill-lock.json`.

## Layout

One directory per tool under `config/`. Name the file for where it lands, not
for the tool, so the step that links it reads as a straight move:
`config/ssh/config` becomes `~/.ssh/config`, and `config/git/gitconfig` becomes
`~/.gitconfig`.

No installed config lives at the repo root. The root holds this repo's own
tooling, like `.shellcheckrc` and `.zed/`, plus symlinks back into `config/`
for tools that insist on finding their config at the root of whatever tree you
open them on. `.editorconfig` and `.luarc.jsonc` are both that.

## Adding a step

One step per tool, named after the tool. It needs the file in `steps/` and an
entry in the `steps` array in `install`. That array sets the run order, so
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

The shell conventions are in `docs/shell-style.md`.

Run the step you changed, as `./install zsh` or `./steps/zsh.bash`. Then run
shellcheck, which passes on this tree:

    shellcheck install upgrade lib/*.bash steps/*.bash config/claude/statusline.sh

A home machine can't exercise the overlay's steps at all, because the overlay
repo isn't there. Say so rather than implying you tested them.
