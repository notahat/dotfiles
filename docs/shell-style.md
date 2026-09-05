# Shell style

The conventions the bash scripts in this repo and the Ferocia overlay
follow. Google's shell style guide is the starting point; where this
document differs from it, this document wins. Shellcheck enforces the rules
it can, using the settings in `.shellcheckrc`.

## Shell

Scripts start with `#!/bin/bash` and use only bash 3.2 syntax. macOS ships
bash 3.2 and nothing newer is installed when `install` first runs. In
particular there are no associative arrays, no `mapfile`, and no `${var,,}`.

Libraries (`lib/*.bash`) have no shebang and are not executable. They start
with `# shellcheck shell=bash`.

## Layout

A script that defines any function is laid out in this order:

1. The `source` line for the library.
2. Constants.
3. Functions.
4. `main "$@"` as the last line.

No executable code sits between function definitions. Top-level logic goes
in `main`. `install` and `steps/ai.bash` are the examples.

A script with no functions of its own is a straight sequence of commands,
as `steps/zsh.bash` is. Don't add a `main` to one of those.

## Naming

| Kind | Form | Example |
| --- | --- | --- |
| Constant, set once and never changed | `UPPER_CASE`, `readonly` | `readonly FEROCIA_DIR="${HOME}/.dotfiles-ferocia"` |
| Exported to the environment | `UPPER_CASE` | `export PATH` |
| Any other variable | `lower_case` | `local overlay_step` |
| Function | `lower_case`, verb first | `run_step`, `link_file` |

A function is declared as `function name() {`, with both the keyword and
the parentheses.

A constant computed from a command or chosen by a condition is assigned
first and made `readonly` on the next line. A single `readonly x=$(...)`
would hide the command's exit status from `errexit`.

```bash
if [[ $(hostname -s) == fer-* ]]; then
  DOTFILES_ENV=ferocia
else
  DOTFILES_ENV=home
fi
readonly DOTFILES_ENV
```

Arrays can be constants too: `readonly STEPS=(...)`.

Function variables are declared `local`. When the value comes from a command
substitution, declare and assign on separate lines for the same
exit-status reason:

```bash
local step
step=$(find_step "$1")
```

## Expansions and quoting

Every named variable is written with braces: `${name}`. Positional
parameters and specials stay bare: `$1`, `$@`, `$?`, `$0`. Shellcheck's
`require-variable-braces` check enforces this.

Every expansion outside `[[ ]]` is double-quoted, even when the value can't
contain whitespace. Inside `[[ ]]`, quotes are only needed on the right-hand
side of `==` when the value must match literally rather than as a pattern.
Shellcheck's `quote-safe-variables` check enforces the first part.

Tests use `[[ ]]`, never `[ ]`. Arithmetic uses `(( ))`. Shellcheck's
`require-double-brackets` check enforces the first.

A bare `~` is fine as a command argument, as in
`link_file config/bat ~/.config/bat`. Inside quotes or an assignment tilde
doesn't expand, so use `${HOME}` there.

Command substitution is `$(...)`, never backticks.

## Comments

Every function has a header comment, including `main`. The header says what
the function does and, where it isn't obvious, why it does it that way.
Plain prose; Google's `Globals:` / `Arguments:` / `Returns:` layout isn't
used.

Comments are complete sentences and describe the code as it is now.

## Errors and output

The library turns on `errexit` and `pipefail` for whatever sources it, so a
step stops at the first failing command without checking each one.

A command whose failure is expected and harmless says so at the call, as in
`defaults read ... 2>/dev/null` inside a test, where a missing key is the
normal case on a fresh machine.

Error messages go to stderr. `echo_red` prints to stdout, so the call adds
`>&2`:

```bash
echo_red "There's no step called \"$1\"." >&2
```

Progress messages go to stdout through `echo_green` or plain `echo`.

## Paths

A library finds its own repo with `realpath` on its parent directory.
`BASH_SOURCE` names the library itself, where `$0` would name whichever
script sourced it:

```bash
DOTFILES_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")
readonly DOTFILES_DIR
```

macOS has shipped `realpath` since Ventura, so there's no need for the
older `cd ... && pwd` idiom.

## Checking

Run shellcheck over the whole tree from the repo root, so `.shellcheckrc`
applies:

```bash
shellcheck install upgrade lib/*.bash steps/*.bash config/claude/statusline.sh
```

Beyond its defaults, `.shellcheckrc` enables `require-variable-braces`,
`require-double-brackets`, `quote-safe-variables` and
`check-unassigned-uppercase`. The last one catches a misspelled constant,
which would otherwise expand to nothing.

There is no formatter. Indentation is two spaces, set by `.editorconfig`.

## Not adopted

Parts of Google's guide that were considered and left out:

- **shfmt.** Tried, and the only changes it wanted were to unalign the
  comments on the `STEPS` array and reorder a here-string. Not worth a
  tool.
- **80-column lines.** Long lines are mostly URLs, `npx` invocations and
  message strings, and wrapping them made each harder to read.
- **File header comments on every step.** A step is a handful of
  `link_file` calls; the filename says what it does.
