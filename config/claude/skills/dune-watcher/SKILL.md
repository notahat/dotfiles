---
name: dune-watcher
description: Drive the `dune runtest -w` watcher as the default test/build loop in OCaml/opam/dune projects. Apply whenever the user is editing `.ml` / `.mli` files, running tests, building, or starting TDD-style work — don't wait to be asked.
---

# Dune watcher workflow

`dune runtest -w` (watch mode) is a long-lived daemon that rebuilds
and re-runs tests on every save. Using it as the default test loop is
much faster than one-shot `dune build` / `dune test` invocations, and
it keeps `_build/` artifacts fresh for merlin / ocaml-lsp.

The skill applies to any project where `dune-project` exists at the
root, with the local opam switch's `bin/` on `PATH` so `dune` resolves
directly (no `opam exec --` prefix).

Two scripts drive it, both taking no arguments and runnable from
anywhere inside the project:

- `~/.claude/skills/dune-watcher/scripts/dune-watch` — starts the
  watcher, writing its output to a deterministic per-project log file.
- `~/.claude/skills/dune-watcher/scripts/dune-check` — reports the
  current build verdict on stdout. Run after every edit.

## The workflow

### Start the watcher (once per session)

Launch with the Bash tool's `run_in_background: true`:

    ~/.claude/skills/dune-watcher/scripts/dune-watch

It truncates `_build/.dune-watcher.log` and execs `dune runtest -w`
with output redirected to it. The process lives for the rest of the
session.

If `_build/.lock` exists, the launcher diagnoses whether another
dune process is running (stop it first) or whether the lock is stale
from a killed daemon (`rm _build/.lock` and re-run).

### After each edit, run `dune-check`

Foreground (no `run_in_background`):

    ~/.claude/skills/dune-watcher/scripts/dune-check

The output is one of:

    PASS (fresh): 412 tests across 23 suites
    Overall: 23/23 known suites green.

    FAIL (fresh): 1 failing test(s), 0 compile error(s)

    <extracted [FAIL] block or File:/Error: block>

    Overall: 22/23 suites green; FAIL: pipeline

The freshness tag in the verdict tells you whether the result is new
since your last call:

- `fresh`     — a rebuild completed during or since the previous
                `dune-check` call.
- `no change` — no rebuild has happened since the previous call;
                this is the latest verdict the watcher emitted.
- `initial`   — first call this session.

Some rebuilds produce no test output (dune's incremental tracker
decides no test executable needs to re-run). `dune-check` reports
that honestly rather than as a misleading "0 tests" PASS.

`Overall:` is the cross-rebuild aggregate of every suite the watcher
has run this session. An incremental rebuild often re-runs only the
suites whose dependencies changed, so the per-rebuild count usually
covers a subset; `Overall:` tells you whether the project as a whole
is still green.

## Don't go around the script

`dune-check`'s stdout is the answer. **Read it once.** If the verdict
isn't enough to act on, that's a bug in the script's output — fix it
there, don't route around it. (Example: "the summary doesn't have
enough detail to fix the failure" is `extract_failure_blocks`
under-extracting, not a licence to grep the log.)

**Don't read these files:**

- `_build/.dune-watcher.log` — the watcher's long-running log
  accumulates output from every rebuild, so a `grep FAIL` returns
  stale failures and invites wrongly concluding "these are
  pre-existing".
- `_build/.dune-watcher.state` — the script's internal counters.

**Don't run these commands:**

- `dune test`, `dune build`, `dune build @fmt`. The watcher holds
  dune's lock, so one-shots hang. The watcher already runs tests on
  every save; `dune-check` is how you read the results.
- `dune exec <name>`, or any wrapper that uses `dune exec`
  internally. Fails with `Program '<name>' not found!` because of
  the lock. Run the artifact directly:

      _build/default/bin/main.exe [args...]

  The watcher keeps it fresh, so no separate build step is needed.
- `touch`, dummy edits, or other tricks to provoke a "current"
  verdict. `dune-check` already reports the current verdict —
  that's what the `no change` / `initial` tags mean.

Format `.ml` / `.mli` with `ocamlformat --inplace <file>` directly,
not via `dune build @fmt --auto-promote`. The project's PostToolUse
hook may already do this on edits — check before adding a manual
format step.

If you genuinely need a one-shot (CI scripts, fresh build from
clean state), stop the watcher first.

## Restarting the watcher

Restart the same way: one backgrounded `dune-watch`. Don't start a
second watcher alongside an existing one, and don't fall back to
ad-hoc `dune test` runs — those will hang against the existing
daemon.

Signs the watcher needs a restart:

- `dune-check` reports exit 1 with "watcher process (PID N) is no
  longer running" — the watcher died, leaving its log behind. Just
  re-run `dune-watch`; it writes a fresh PID file and truncates the
  log.
- `dune-check` reports exit 1 with "no PID file ... cannot verify
  the watcher is alive" — the watcher predates the current
  `dune-watch` script (no PID file was written). Re-run `dune-watch`.
- `dune-check` reports exit 1 with "no watcher log" or "is the
  watcher running?".
- `_build/.lock` exists but no dune process is running (stale lock
  from a killed daemon — remove the lock file, then restart).

## How `dune-check` works

`dune-check` reads the watcher log, waits for any in-flight rebuild
to settle (≤ 120 s ceiling), and reports the verdict of the most
recent rebuild. The mechanism — counters, the marker-order idle
signal, the two-phase wait, the empirical findings about dune's
output format, and the alternatives that were tried and rejected —
is in `references/dune-watcher.md`.

## Failure modes

- **Concurrent fs events from other tooling.** If an editor's
  auto-formatter or a hook writes to a build file mid-rebuild, the
  watcher starts a second rebuild and `dune-check` may report the
  second one's results when you were expecting the first.
  Mitigation: don't fire unrelated tools mid-rebuild.
- **Dune output format changing.** `dune-check` hard-codes two
  phrases: `********** NEW BUILD` and `waiting for filesystem`.
  Both have been stable across recent dune releases but aren't part
  of any documented interface. If a future dune reworks watcher
  output, the failure mode is loud (exit 1, "watcher may be stuck"),
  not silent.

## Quick reference

    # Once per session, in the project root:
    ~/.claude/skills/dune-watcher/scripts/dune-watch      # background

    # After every edit (or whenever you want the current verdict):
    ~/.claude/skills/dune-watcher/scripts/dune-check      # foreground

    # Run the binary while the watcher is up:
    _build/default/bin/main.exe [args...]                 # NOT dune exec

    # Format a file while the watcher is up:
    ocamlformat --inplace path/to/file.ml                 # NOT dune build @fmt
