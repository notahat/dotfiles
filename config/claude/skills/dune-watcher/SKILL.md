---
name: dune-watcher
description: Drive the `dune runtest -w` watcher as the default test/build loop in OCaml/opam/dune projects, including the wait-for-rebuild protocol after each edit and the rules for what NOT to run while the watcher is up. Use this skill whenever you are working in an OCaml project that uses dune — whether the user says "set up the dune watcher", "start the watcher", or simply begins TDD-style work, runs tests, or asks you to build the project. If the user is editing `.ml` / `.mli` files or invoking `dune test` / `dune build`, this skill applies — don't wait to be asked.
---

# Dune watcher workflow

`dune runtest -w` (watch mode) is a long-lived daemon that rebuilds and
re-runs the test suite on every file save. Using it as the default test
loop is much faster than one-shot `dune build` / `dune test` invocations,
and it keeps `_build/` artifacts fresh so merlin / ocaml-lsp gets live
diagnostics. This skill is the protocol for driving that watcher
correctly.

The watcher's output is prose for humans, not a protocol — there's no
machine-readable event stream — so the wait protocol below infers state
from two stable phrases in the watcher's log. The bundled
`scripts/wait-for-watcher.sh` does the parsing.

## When this applies

Any project where `dune-project` exists at the root. The whole skill
assumes the local opam switch's `bin/` is on `PATH`, so `dune` resolves
directly (no `opam exec --` prefix). If your shell needs the prefix,
add it to every command below.

## Starting the watcher

Start once per session as a long-lived background task. The `Bash` tool's
`run_in_background: true` is the right mechanism — it returns a log path
you keep for the rest of the session as `$LOG`:

    dune runtest -w

You do not need to start a second watcher later. If `_build/.lock` is
already held when you start, another watcher (or a stuck one-shot) is
running — sort that out before launching a second daemon.

## What NOT to run while the watcher is up

The watcher holds dune's instance lock. Any one-shot dune command
forwards to the watcher daemon, which only does what it was started to
do — so the one-shot hangs. The consequence:

- **No `dune test`, `dune build`, `dune build @fmt` while the watcher is
  up.** Read test results from `$LOG` instead. The watcher is already
  running tests on every save.
- **No `dune exec <name>` and no wrapper script that uses `dune exec`
  internally.** It fails with `Program '<name>' not found!` because the
  lock is held. Run the artifact directly:

      _build/default/bin/main.exe [args...]

  The watcher keeps it fresh, so no separate build step is needed.
- **Format with `ocamlformat --inplace <file>` directly**, not via
  `dune build @fmt --auto-promote`. The project's PostToolUse hook may
  already do this on `.ml` / `.mli` edits — check before adding manual
  formatting steps.

If you genuinely need a one-shot (e.g. CI scripts, a fresh build from
clean state), stop the watcher first.

## The wait-for-rebuild protocol

After every edit to a build-relevant file (`.ml`, `.mli`, `dune`,
`dune-project`, etc.) you need to wait for the watcher's rebuild to
finish before reading results. The protocol is **capture baseline →
edit → run wait script**:

    # Capture BEFORE the edit. This is the count of completed rebuilds
    # so far; the wait script watches for it to increase.
    before=$(grep -c "waiting for filesystem" "$LOG")

    # ... make your edits (Edit / Write tool calls) ...

    # Run in the background. The script prints the new rebuild's output
    # and exits, which fires a single notification.
    scripts/wait-for-watcher.sh "$LOG" "$before"

Use `run_in_background: true` for the wait script. You'll get notified
the moment the rebuild settles.

The script lives in this skill at
`~/.claude/skills/dune-watcher/scripts/wait-for-watcher.sh`. Either
reference that path directly, or copy it into the project's `scripts/`
directory at setup time (the dovetail project, where this protocol
originated, keeps a project-local copy).

### Exit codes

- **0**: the rebuild settled (output printed), **or** dune chose not to
  rebuild (no-op edit, content-unchanged `touch`, edit to a non-build
  file, or coalesced into an earlier rebuild). The "no rebuild" case
  prints a note on stderr — that is normal, not a failure.
- **1**: the 120-second ceiling fired. The watcher is likely stuck; the
  last 100 lines of the log get dumped to stderr.

### Why the baseline goes *before* the edit

The watcher reacts to filesystem events in 17–47 ms. If you capture the
baseline after the edit, you can race the watcher and miss its log
update. Capturing before the edit means the script can detect even a
rebuild that finished before it started polling — see "Phase 1" in
`references/dune-watcher.md` for the full reasoning.

### Why not other approaches

The script's two-phase design exists because none of the obvious
alternatives work:

- **Fixed `sleep`**: either too short (false claim of "done" mid-compile)
  or too long (every edit pays the worst case).
- **Single idle-threshold heuristic**: real rebuilds have multi-second
  quiet gaps inside them (compile phase before any test output), so any
  idle window long enough to be safe is too long to detect a no-op
  edit quickly. Two phases let each gate use the signal that actually
  diagnoses its question.
- **`Monitor` tool**: designed for "one notification per occurrence,
  indefinitely"; its own schema recommends `Bash` + `run_in_background`
  for one-shot "wait until X" cases.
- **`tail -F | grep -m 1 ...`**: `tail -F` doesn't notice the pipeline
  is gone until it next tries to write, so it hangs if the log goes
  quiet after the match.
- **`dune rpc`**: dune exposes a JSON-RPC socket but it's an unstable
  internal API and the "wait for next build" surface is unclear.

If you find yourself reaching for any of these, use the script instead.

## Restarting the watcher

If the watcher dies or was never started, restart it the same way: one
backgrounded `dune runtest -w`. Don't start a second watcher alongside
an existing one, and don't fall back to ad-hoc `dune test` runs — those
will hang against the existing daemon and waste the cycle.

Signs the watcher needs a restart:

- `$LOG` stopped growing on edits that should have triggered a rebuild,
  and the wait script is hitting its Phase 1 timeout.
- `_build/.lock` is held but no watcher process exists (stale lock
  from a killed daemon — remove the lock file, then restart).

## Failure modes to be aware of

These are documented limitations of the wait protocol, not bugs:

- **Concurrent fs events from other tooling.** If an editor
  auto-formatter, an MCP hook, or `git checkout` writes to a build
  file during Phase 2, the watcher starts a second rebuild whose
  sentinel will satisfy our wait — the caller gets the *wrong*
  rebuild's results. Mitigation: don't fire unrelated tools mid-wait.
- **Dune output format changing.** The script hard-codes two phrases:
  `********** NEW BUILD` and `waiting for filesystem`. Both have been
  stable across recent dune releases but aren't part of any documented
  interface. If a future dune reworks watcher output, the failure mode
  is loud (Phase 1 or Phase 2 timeout), not silent.

## Deeper reference

`references/dune-watcher.md` (bundled with this skill) captures the
empirical findings the wait protocol is built on: what dune actually
emits per rebuild, measured timings, the rationale for the two-phase
strategy, and the alternatives that were tried and rejected. Read it
when:

- The wait script starts misbehaving (e.g. Phase 1 timing out on
  edits that clearly should rebuild, or Phase 2 settling on the wrong
  rebuild) and you need to understand the assumptions to diagnose.
- You're tempted to "fix" the script with a simpler approach
  (`tail -F | grep`, fixed sleep, dune rpc, etc.) — the doc covers
  why each of those was rejected.
- Dune's watcher output format appears to have changed; the doc
  names the two hard-coded phrases the script depends on.

The empirical numbers in that doc were measured against dune 3.23.0 in
one specific project, so the absolute timings are illustrative; the
*shape* of the findings (no-op vs. real-rebuild signal, multi-second
quiet gaps inside a compile) is what generalises.

## Quick reference

```
# Once per session:
dune runtest -w                              # run_in_background, save path as $LOG

# Per edit cycle:
before=$(grep -c "waiting for filesystem" "$LOG")
# ... edits ...
~/.claude/skills/dune-watcher/scripts/wait-for-watcher.sh "$LOG" "$before"
                                             # run_in_background

# Running the binary while watcher is up:
_build/default/bin/main.exe [args...]        # NOT `dune exec ...`

# Formatting while watcher is up:
ocamlformat --inplace path/to/file.ml        # NOT `dune build @fmt`
```
