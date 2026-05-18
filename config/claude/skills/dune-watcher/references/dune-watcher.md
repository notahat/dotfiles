# Detecting dune watcher rebuilds

## Why this needs a doc

The dune build system in watch mode (`dune runtest -w`) is the
project's primary test loop: a long-lived process that rebuilds and
re-runs the suite on every file save. Claude needs to wait for the
rebuild that a given edit triggered to finish, then read the results —
without running `dune build` / `dune test` directly, since those
one-shots forward to the watcher daemon and hang.

The watcher's output is prose for humans, not a protocol. There is no
machine-readable event stream, so the strategy is to infer state from
text. This document records what dune actually emits, the strategy
`scripts/wait-for-watcher.sh` uses to parse it, and the alternatives
considered and rejected.

The empirical findings here are from dune 3.23.0; the strings the
script depends on have been stable across recent versions but could
shift in future, so the two hard-coded phrases (see "Strategy") are
the main risk surface.

## What dune actually emits

Probed empirically on 2026-05-18 with dune 3.23.0 in this repo.

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
prints no `NEW BUILD` marker, only the end marker. From the second
rebuild onwards, `NEW BUILD` and end-marker counts move in lockstep.

### What different events produce

| Event                                | Bytes written | NEW BUILD     | End marker                 |
| ---                                  | ---           | ---           | ---                        |
| `touch` with no content change       | 0             | no            | no                         |
| Edit to non-build file (e.g. `.md`)  | 0             | no            | no                         |
| Real `.ml` edit → compile error      | grows         | yes           | `Had N errors`             |
| Real `.ml` edit → green              | grows         | yes           | `Success`                  |
| Three rapid edits in succession      | grows         | yes — *one*   | yes — *one* (coalesced)    |

### Timing observations

| Phase                                            | Measured     |
| ---                                              | ---          |
| Edit → first byte appears in watcher log         | 17–47 ms     |
| Trivial green rebuild (comment-only change)      | ~50 ms total |
| Compile error                                    | ~6 s         |
| Real test work (breaking a `Value` test)         | ~22 s total  |

The 22-second rebuild had quiet stretches inside it — a compile phase
before any test output, then bursts of test output, with multi-second
gaps where dune is recompiling but emitting nothing. The gaps are the
specific reason a single idle-threshold heuristic doesn't work; see
"Why two phases" below.

## Strategy

`scripts/wait-for-watcher.sh` is a two-phase, two-counter script.

### Counters

- *Sentinel count*: occurrences of `waiting for filesystem` in the
  log. The caller captures this **before** the edit and passes it in.
- *NEW BUILD count*: occurrences of `********** NEW BUILD` in the log.
  The script captures this at its own start, internally.

### Phase 1 — "did the watcher decide to rebuild?" (≤ 2 s)

Poll every 100 ms. On each tick:

- If the sentinel count is already past the caller's baseline, the
  rebuild finished before we started polling (we raced and lost).
  Print the rebuild output and exit 0.
- If the `NEW BUILD` count is past the script's own baseline, a real
  rebuild is in flight. Go to Phase 2.
- If 2 s elapse with neither advancing, the watcher chose not to
  rebuild (content hash unchanged, edit to a non-build file, or
  coalesced into another rebuild that has already settled). Print a
  note and exit 0.

Two seconds is comfortable headroom: dune's measured reaction is
17–47 ms, so we have ~50× margin before declaring a no-op. The
100 ms poll keeps the response snappy on a real rebuild.

### Phase 2 — "wait for the rebuild to finish" (hard ceiling 120 s)

Poll every 500 ms. Exit 0 the moment the sentinel count exceeds the
caller's baseline. If 120 s elapse without that, exit 1 (genuinely
stuck watcher).

No idle-bail. Once Phase 1 confirmed a `NEW BUILD` marker, we know
dune is working; a 10-second quiet stretch in the middle of a
compile is not a sign of failure.

### Why two phases

The previous one-phase script collapsed two distinct questions into a
single 5-second idle threshold:

- "Did the watcher decide to rebuild?" — answered by a *short* window.
- "Has the in-progress rebuild finished?" — answered by a window
  *long enough to absorb compile gaps*, potentially minutes.

No single timeout can answer both. Five seconds was wrong in both
directions: long enough that no-op detection felt sluggish; short
enough to falsely trip during a real 22-second rebuild's compile
phase. Splitting the question lets each gate use a signal that's
diagnostic of the thing it's actually checking.

## Alternatives considered

### `Monitor` tool

Streams one event per stdout line; designed for "one notification per
occurrence, indefinitely." The Monitor schema explicitly recommends
`Bash` + `run_in_background` for one-shot "wait until X" cases, which
is what we have here. Using Monitor would fire a notification on every
rebuild regardless of whether Claude was currently waiting, and the
notification timing would drift from the edit it followed. Wrong shape
for this job.

### `dune rpc`

Dune exposes a JSON-RPC socket at `_build/.rpc/dune`. In principle a
client could subscribe to build state. In practice this is an
unstable internal API, the surface for "wait for next build to
finish" is unclear, and one-shot dune commands that forward to the
daemon already hang on this repo. Not pursued.

### `tail -F | grep -m 1 "waiting for filesystem"`

Looks tempting because it's event-driven and exits on first match.
Doesn't work: `tail -F` only learns the pipeline downstream is gone
when it next tries to write. If the log goes quiet right after the
match, `tail` never receives `SIGPIPE` and the pipeline hangs. The
Monitor tool's schema documents this same hazard.

### Single byte-size signal instead of NEW BUILD marker

Workable in principle (no-op rebuilds write zero bytes; real rebuilds
write something), but the `NEW BUILD` marker is a more semantic
signal and includes the path of the changed file as a bonus. The
script uses the marker.

## Failure modes intentionally not handled

### Concurrent fs events from other tooling

If the editor's auto-formatter, an MCP hook, or `git checkout` writes
to a build file during Phase 2, the watcher will start a *second*
rebuild whose sentinel will satisfy our wait — and the caller will
get the wrong rebuild's results. Detecting this would need
per-rebuild sequence numbers, which dune doesn't expose. Cost is
high, probability is low, mitigation lives in caller discipline
(don't fire unrelated tools mid-wait).

### Dune output format changing

The script hard-codes two phrases: `********** NEW BUILD` and
`waiting for filesystem`. Both have been stable across recent dune
releases but are not part of any documented interface. A future dune
that reworks watcher output will need this script updated; the
failure mode is loud (timeout in Phase 1 or Phase 2), not silent.
