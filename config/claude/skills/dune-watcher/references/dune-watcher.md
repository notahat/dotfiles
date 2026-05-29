# Detecting dune watcher rebuilds

## Why this needs a doc

The dune build system in watch mode (`dune runtest -w`) is a
project's primary test loop: a long-lived process that rebuilds and
re-runs the suite on every file save. We need to wait for the
rebuild that a given edit triggered to finish and read the results
— without running `dune build` / `dune test` directly, since those
one-shots forward to the watcher daemon and hang.

The watcher's output is prose for humans, not a protocol. There is
no machine-readable event stream, so the strategy is to infer state
from text. This document records what dune actually emits, the
strategy `scripts/dune-check` uses to parse it, and the
alternatives considered and rejected.

The empirical findings here are from dune 3.23.0; the strings
`dune-check` depends on have been stable across recent versions but
could shift in future, so the two hard-coded phrases (see
"Strategy") are the main risk surface.

## What dune actually emits

Probed empirically with dune 3.23.0 in the dovetail repo.

### Per-rebuild structural markers

Every rebuild triggered by a real fs event prints, in order:

1. A start marker on its own line:

       ********** NEW BUILD (lib/core/value.ml changed) **********

   The path identifies which file dune picked up.

2. Build output (compile errors, test output, summary lines).

3. An end marker, exactly one of:

       Success, waiting for filesystem changes...
       Had N error[s], waiting for filesystem changes...

The very first build after watcher startup is the only exception: it
prints no `NEW BUILD` marker, only the end marker.

The two counts do **not** move in lockstep. When a filesystem event
arrives while a rebuild is already in progress, dune abandons the
in-progress rebuild and starts a fresh one with another `NEW BUILD`
marker -- without ever emitting a sentinel for the abandoned one. So
a watcher that has been idle for a while can have e.g. four `NEW
BUILD` markers and three sentinels. The script must not rely on
"`NEW BUILD` count + 1 == sentinel count" as the idle invariant.

### What different events produce

| Event                                | Bytes written | NEW BUILD     | End marker                 |
| ---                                  | ---           | ---           | ---                        |
| `touch` with no content change       | 0             | no            | no                         |
| Edit to non-build file (e.g. `.md`)  | 0             | no            | no                         |
| Real `.ml` edit → compile error      | grows         | yes           | `Had N errors`             |
| Real `.ml` edit → green              | grows         | yes           | `Success`                  |
| Edit that reverts to a cached state  | small         | yes           | `Success` (no test output) |
| Three rapid edits in succession      | grows         | one *or more* | one (only the final completes) |

The "reverts to cached state" row is real: dune's incremental cache
will skip recompilation and retest if the post-edit source matches
something it already has cached. The rebuild block still appears
(`NEW BUILD` + `Success` sentinel) but has no `Testing` /
compile-error output between them.

### Timing observations

| Phase                                            | Measured     |
| ---                                              | ---          |
| Edit → first byte appears in watcher log         | 17–47 ms     |
| Trivial green rebuild (comment-only change)      | ~50 ms total |
| Rebuild that hits cache (revert to known state)  | < 1 s        |
| Compile error                                    | ~6 s         |
| Real test work (breaking a `Value` test)         | ~22 s total  |

The 22-second rebuild had quiet stretches inside it — a compile
phase before any test output, then bursts of test output, with
multi-second gaps where dune is recompiling but emitting nothing.
The gaps are the specific reason a single idle-threshold heuristic
doesn't work; see "Why two phases" below.

## Strategy

`scripts/dune-check` runs inline and persists two counters between
calls. The counters detect *change*; a separate signal -- the type
of the most recent marker in the log -- decides whether the watcher
is currently *idle*. Before any of that, a liveness check confirms
that the log we are about to parse belongs to a watcher that is
still running.

### Liveness: is the log we are reading still owned by a live process?

`dune-watch` writes its PID to `_build/.dune-watcher.pid` just before
`exec dune runtest -w`. Because `exec` replaces the shell in place
without changing the PID, the recorded PID is the running watcher's.
`dune-check` reads the file and calls `os.kill(pid, 0)` -- the
canonical "is this PID still around?" probe -- and refuses to report
a verdict from a log whose owner is gone.

The case this closes: a watcher dies (terminal closed, OOM kill,
crash) leaving the log behind. The next `dune-check` would otherwise
parse the orphaned log and report a "PASS" verdict that describes
the state of the source tree as it was at the moment the dead
watcher last finished a rebuild -- potentially many edits ago. The
caller takes the verdict at face value and trusts that their recent
edits are validated. They are not. The fix turns this into a
visible error: "watcher process (PID N) is no longer running;
restart the watcher".

PID reuse is theoretically possible (a long-lived unrelated process
could pick up the recycled PID before `dune-check` probes it), but
PIDs are reused slowly on modern kernels and the failure mode is
"report a verdict that turns out to be from a different watcher
session" -- exactly the failure mode the user just restarted to
escape. Not worth a richer signature.

### Counters and the idle signal

- *Sentinel count*: occurrences of `waiting for filesystem` in the
  log. Increments at the end of every rebuild dune completed.
- *NEW BUILD count*: occurrences of `********** NEW BUILD`.
  Increments at the start of every rebuild from the second one
  onwards, including rebuilds that get coalesced (abandoned and
  re-started without a sentinel).
- *Last marker*: which kind of marker is most recent in the log.
  This is the idle signal: idle iff the last marker is a sentinel,
  in flight iff the last marker is a `NEW BUILD`.

A single pass over the log returns all three. The two counts are
persisted in `_build/.dune-watcher.state` at the end of each
`dune-check` call so the next call has a baseline for "did anything
new happen?". The last marker is recomputed on every poll and is
never persisted -- it describes only the current state.

The temptation to use the counts to decide idle ("idle iff sentinel
== new_build + 1") fails under coalescing: dune can permanently
have more `NEW BUILD` markers than sentinels. The marker-order
signal stays accurate regardless.

### Per-call decision tree

On entry, `dune-check` reads the saved counters and scans the log
for the three current values: sentinel count, NEW BUILD count, last
marker.

- First call this session (no saved state): if the log has no
  markers at all, run Phase 1 to give the watcher a chance to
  start. If still nothing, report stuck. Otherwise wait until idle
  (Phase 2) and report `initial`.
- Otherwise, if neither counter has advanced past its saved
  baseline: the caller may have just edited a file and the watcher
  hasn't reacted yet. Run Phase 1 to catch the start of a rebuild.
- Then, if the watcher is in flight (last marker is `NEW BUILD`),
  wait until idle (Phase 2). This is the step that catches the
  "rebuild in flight when we entered, or a new one queued behind
  the one whose sentinel we observed".
- Decide freshness from the (post-settle) counters: `fresh` if
  either counter has advanced past its saved baseline, otherwise
  `no change`.

### Phase 1 — "did the watcher decide to rebuild?" (≤ 2 s)

Poll every 100 ms. Return as soon as either counter advances past
its baseline; return `idle` if 2 s elapse with neither.

Two seconds is comfortable headroom: dune's measured reaction is
17–47 ms, so we have ~50× margin. The 100 ms poll keeps the
response snappy.

### Phase 2 — "wait until the watcher is idle" (hard ceiling 120 s)

Poll every 500 ms. Re-scan the log on each tick. Exit the moment
the last marker is a sentinel; if 120 s elapse without that, exit
1 (genuinely stuck watcher).

No idle-bail. Once we've confirmed the watcher is processing
something, a 10-second quiet stretch in the middle of a compile is
not a sign of failure.

Crucially, the loop re-reads the log every tick rather than waiting
for any particular sentinel-count target. That's what catches
coalesced or stacked-up rebuilds: a sentinel may appear in the log
while another `NEW BUILD` is already past it; the loop keeps
waiting until *the most recent* marker is a sentinel.

### Why the marker-order signal beats a count-based invariant

A previous version of this script tried to decide idle from the
counts alone, on the assumption that `NEW BUILD` and sentinel
counts move in lockstep from the second rebuild onwards. They
don't. Dune's coalescing -- abandoning an in-progress rebuild when
a new filesystem event arrives, without ever emitting a sentinel
for the abandoned one -- means the script can encounter four `NEW
BUILD` markers and three sentinels at a fully idle watcher. The
count-based invariant either reports false stuck-states or
reports premature "fresh" verdicts mid-rebuild.

The marker-order signal handles coalescing for free: only the
final marker matters, not the running counts.

### Why two phases

The original one-phase script collapsed two distinct questions into
a single 5-second idle threshold:

- "Did the watcher decide to rebuild?" — answered by a *short*
  window.
- "Has the in-progress rebuild finished?" — answered by a window
  *long enough to absorb compile gaps*, potentially minutes.

No single timeout can answer both. Five seconds was wrong in both
directions: long enough that no-op detection felt sluggish; short
enough to falsely trip during a real 22-second rebuild's compile
phase. Splitting the question lets each gate use a signal that's
diagnostic of the thing it's actually checking.

## Alternatives considered

### Background-task notification model (the previous design)

The previous `wait-for-watcher.py` was launched with
`run_in_background: true`; the caller read its per-invocation
output file when notified. That model assumed long rebuilds where
parallel work was useful. In practice most rebuilds were sub-second
(dune's incremental cache is fast), so backgrounding added two
ceremony steps (launch, then `Read` the output file) for negligible
benefit. The foreground inline model puts the verdict where the
caller is already looking.

### Single-call with explicit `mark` subcommand (the previous protocol)

Required calling `mark` before every edit. Easy to forget, and
forgetting silently broke baselining. The two-counter state file
removes the need for an explicit mark step.

### `Monitor` tool

Streams one event per stdout line; designed for "one notification
per occurrence, indefinitely." Wrong shape for "wait until next
rebuild finishes."

### `dune rpc`

Dune exposes a JSON-RPC socket at `_build/.rpc/dune`. In principle
a client could subscribe to build state. In practice this is an
unstable internal API and the surface for "wait for next build to
finish" is unclear. Not pursued.

### `tail -F | grep -m 1 "waiting for filesystem"`

`tail -F` only learns the pipeline downstream is gone when it next
tries to write. If the log goes quiet right after the match, `tail`
never receives `SIGPIPE` and the pipeline hangs.

### Single byte-size signal instead of NEW BUILD marker

Workable in principle (no-op rebuilds write zero bytes; real
rebuilds write something), but the `NEW BUILD` marker is a more
semantic signal and includes the path of the changed file as a
bonus. The script uses the marker.

## Failure modes intentionally not handled

### Concurrent fs events from other tooling

If the editor's auto-formatter, an MCP hook, or `git checkout`
writes to a build file during Phase 2, the watcher starts a second
rebuild and `dune-check` keeps waiting until *that* one finishes
too -- the marker-order idle signal means we report the most recent
settled rebuild, not whichever one was in flight when we entered.
That's the right answer for the common case (the caller ran
`dune-check` after an edit and wants the latest verdict), but it
does mean the verdict may reflect a rebuild that wasn't triggered
by the caller's most recent edit. Distinguishing which rebuild was
"theirs" would need per-rebuild sequence numbers, which dune
doesn't expose. Cost is high, probability of confusion is low.

### Dune output format changing

The script hard-codes two phrases: `********** NEW BUILD` and
`waiting for filesystem`. Both have been stable across recent dune
releases but are not part of any documented interface. A future
dune that reworks watcher output will need the script updated; the
failure mode is loud (exit 1, "watcher may be stuck"), not silent.

## Maintaining this script

### Looking at the log when debugging

The skill's SKILL.md tells callers not to peek at
`_build/.dune-watcher.log` during the routine code-change cycle --
that's about trusting `dune-check`'s verdict, and the rule is
sound. **That rule does not apply when the script itself is the
subject of work.** When the question is "what does dune actually
emit?" or "why did `dune-check` give a surprising verdict?", the
log is the input to the system under test. Looking at it with
`grep -n` for markers, or `Read` for context, is how this script
gets fixed at all. The empirical findings table earlier in this
doc would not exist without that.

### If you reach for the log mid-cycle, the script is the bug

A stronger version of the same rule: if you find yourself wanting
to look at the log to resolve ambiguity in a `dune-check` verdict
during ordinary work -- "did the build actually succeed?", "are
these failures from this rebuild or a previous one?", "is it still
running?" -- that is a signal that the verdict should have been
clearer, not that you should improve your reading habit. Fix the
script's output instead. This doc has at least one entry that
exists because of exactly that pattern (the "build succeeded; no
tests re-run" branch was reworded after a session where its old
wording -- "rebuild completed; nothing to retest (dune cache hit)"
-- read like "nothing happened" and sent the reader to check
`_build/` timestamps to confirm the build had run).
